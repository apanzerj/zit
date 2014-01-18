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
      system.ping_back
    end
    
    
    def ready
      @g = Git.open(Dir.pwd)
      current_branch = @g.current_branch.to_s
      zt = Zit::ZendeskTicket.new
      ticket_id = current_branch.match(/.*?\/zd(\d{1,8})/)[1]
      puts "Ticket ID detected as #{ticket_id}"
      ticket = zt.get_ticket(ticket_id)
      rep_steps = get_repsteps(ticket)
      link = "#{pr_link}#{current_branch}"
      `open #{link}?pull_request[title]=ZD#{ticket_id}&pull_request[body]=#{CGI.escape(rep_steps)}`
    end
    
    private
    
    def checkout_master
      puts "Attempting to switch to master..."
      master = @g.branches[:master]
      Zit::Error.new("Couldn't find branch master! #{master.inspect}") unless master
      master.checkout
    end

    def pr_link
      link = "#{BASE_REPO}/compare/master..."
    end

    def get_repsteps(ticket)
      audits = ticket.audits.fetch
      aud = audits.detect do |audit|
        next unless audit.events.map(&:type).include?("Change")
        next unless audit.events.map(&:field_name).include?("tags")
        next unless audit.events.map(&:value).join(" ").include?("macro_1234")
        audit
      end
      return aud.events.detect{|c| c.type == "Comment"}.body if aud.present?
      return "No replication steps found\n"
    end
  end
end
