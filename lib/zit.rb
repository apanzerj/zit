require "zit/version"
require "zit/jira_client"
require "zit/management"
require "zit/settings"
require "git"
require "zendesk_api"
require "CGI"
require "httparty"
require "octokit"
module Zit
  
  TOKEN = ENV['zendesk_token']
  USER = ENV['zendesk_user']
  
  JIRA_USER = ENV['jira_user']
  JIRA_PASS = ENV['jira_pass']

  class Error
    def initialize(msg)
      puts "Error: #{msg}"
      exit
    end
  end

  class Zap

    def init(fk, connector, project=nil, quiet)
      # get settings from .zit
      @settings = Zit::Settings.new

      # initialize issue/ticket system
      system = Zit::Management.new({:system => connector, :foreign_key => fk, :project=>project}, @settings)
      
      #gather git data
      Zit::Error.new("Not a git repository") unless File.directory?(".git")
      @g = Git.open(Dir.pwd)

      # make sure we haven't changed repos
      validate_repo

      # branch off of master!
      checkout_master unless @g.current_branch.to_s == "master"

      # derive the proper github username
      begin
        name = @g.config()["github.user"]
        @settings.update_setting("gitname", name.to_s) if (@settings.get("gitname") == "doody" || @settings.get("gitname") != name)
      rescue Git::GitExecuteError
        puts "Github user not set! Using defualt 'doody'..."
        name = "doody"
      end
      
      # name the new branch and checkout
      new_branch = system.branch_name(name)
      @g.branch(new_branch.to_s).checkout
      
      # set last system and last branch
      @settings.update_settings({:last_system => connector, :last_branch => new_branch})

      # Provide a ping_back message
      msg = "A branch for this #{connector == :jira ? "issue" : "ticket" } has been created. It should be named #{new_branch}."
      system.ping_back(msg) unless quiet
    end

    def finish(quiet)
      # Description: Finish workflow by calling ready. This method is the start of the "closing up" workflow.
      settings = Zit::Settings.new

      @g = Git.open(Dir.pwd)
      @options = {}
      @options[:current_branch] = @g.current_branch.to_s
      
      # Create message for ping_back
      msg = "A pull request is being made for this branch."

      # Create the needed options hash
      @options[:current_branch].match(/.*?\/zd(\d{1,8})/).nil? ? jira_ready : zendesk_ready
      
      # Initialize system object
      system = Zit::Management.new(@options, settings)

      # Ping_back and pick comment.
      # If the ENV['gh_api_key'] is nill, we want to ping back since we won't be updating the ticket
      # with a PR link.

      system.ping_back("A pull request for your branch is being created") unless (quiet || ENV['gh_api_key'].nil?)
      system.ready
    end

    def update
      # read settings
      settings = Zit::Settings.new

      # get GitHub key
      gh_key = ENV['gh_api_key']
      Zit::Error.new("GitHub key is missing! Can't update.") if gh_key.nil?

      # Get the owner / repo and get relevant PR url
      (owner, repo) = settings.get("base_repo").match(/com\/(.*?)\/(.*?)$/)[1..2]
      response = HTTParty.get("https://api.github.com/repos/#{owner}/#{repo}/pulls", :query=>{:state => "open"}, :basic_auth => {:username => gh_key, :password=> "x-oauth-basic"}, :headers => {"User-Agent" => "zit_gem_0.0.1"})
      selected_pr = response.select do |pr|
        next if pr["head"]["ref"] != settings.get("last_branch")
        pr
      end
      url = selected_pr.first["html_url"]

      # Get necessary options for system ping_back
      @options = {:current_branch => settings.get("last_branch")}
      settings.get("last_system") == :zendesk ? zendesk_ready : jira_ready

      # ping_back
      system = Zit::Management.new(@options, settings)
      system.ping_back("PR: #{url}")
    end
        
    private
    
    def checkout_master
      # This is REALLY slow for large repos... Take out? Took me 24 seconds to get to master
      puts "Attempting to switch to master..."
      master = @g.branches[:master]
      Zit::Error.new("Couldn't find branch master! #{master.inspect}") unless master
      @g.checkout master.to_s
    end
    

    # The following methods are for creating the options hash. If you want to change how your branches are named
    # then these methods need to be updated. 

    def jira_ready
      @options[:system]       = :jira
      mchdata = @options[:current_branch].match(/.*?\/([A-Za-z].*?)_(\d.*)/)
      @options[:project]      = mchdata[1]
      @options[:foreign_key]  = mchdata[2]
    end
    
    def zendesk_ready
      @options[:system] = :zendesk
      @options[:foreign_key] = @options[:current_branch].match(/.*?\/zd(\d{1,8})/)[1]
    end

    def validate_repo
      # we need to make sure we haven't moved to a different local repo then last time.

      (owner, repo) = @g.remote.url.to_s.match(/com:(.*)\/(.*)\.git$/)[1..2]
      base_repo = "https://github.com/#{owner}/#{repo}"
      unless base_repo == @settings.get("base_repo")
        @settings.update_setting(:base_repo, "https://github.com/#{owner}/#{repo}")
      end
    end
  end

  class Alfred
    def initialize(options)
      list_repos if options[:repos]
    end
  end

  class AlfredPrinter
    def initialize()
    end
end
