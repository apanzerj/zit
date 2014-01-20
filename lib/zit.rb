require "zit/version"
require "zit/jira_client"
require "zit/management"
require "git"
require "zendesk_api"
require "CGI"
require "httparty"

module Zit
  BASE_REPO = "https://github.com/apanzerj/test_repo"
  
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
    def init(fk, connector, project=nil)
      #initialize issue/ticket system
      system = Zit::Management.new({:system => connector, :foreign_key => fk, :project=>project})
      
      #gather git data
      Zit::Error.new("Not a git repository") unless File.directory?(".git")
      puts "Found .git"
      @g = Git.open(Dir.pwd)
      checkout_master
      begin
        name = @g.config('github.user')
      rescue Git::GitExecuteError
        puts "Git name not set! Using doody..."
        name = "doody"
      end
      
      #name the new branch
      new_branch = system.branch_name(name)
      @g.branch(new_branch).checkout
      msg = "A branch for this #{connector == :jira ? "issue" : "ticket" } has been created. It should be named #{new_branch}."
      system.ping_back(msg)
    end

    def ready
      @g = Git.open(Dir.pwd)
      @options = {}
      @options[:current_branch] = @g.current_branch.to_s
      msg = "A pull request is being made for this branch."
      @options[:current_branch].match(/.*?\/zd(\d{1,8})/).nil? ? jira_ready : zendesk_ready
      system = Zit::Management.new(@options)
      #system.ping_back("A pull request for your branch is being created")
      system.ready
    end
    
        
    private
    
    def checkout_master
      puts "Attempting to switch to master..."
      master = @g.branches[:master]
      Zit::Error.new("Couldn't find branch master! #{master.inspect}") unless master
      master.checkout
    end
    
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
  end
end
