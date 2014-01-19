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
      msg = "A branch for this #{connector == :jira ? "issue" : "ticket" } has been created. It should be named #{@options[:branch_name]}."
      system.ping_back(msg)
    end
    
        
    private
    
    def checkout_master
      puts "Attempting to switch to master..."
      master = @g.branches[:master]
      Zit::Error.new("Couldn't find branch master! #{master.inspect}") unless master
      master.checkout
    end

  end
end
