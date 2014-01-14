require "zit/version"
require "git"
require "zendesk_api"
require "CGI"

module Zit
  BASE_REPO = "https://github.com/apanzerj/test_repo"
  TOKEN = ENV['zendesk_token']
  USER = ENV['zendesk_user']

  class Error
    def initialize(msg)
      puts "Error: #{msg}"
      exit
    end
  end
  
  class ZendeskTicket    
    def initialize
      env_set = (TOKEN.is_a?(String) && TOKEN.size > 0) && (USER.is_a?(String) && USER.size > 0)
      Zit::Error.new("Unable to locate the zendesk_token and zendesk_user environment variables. Please set them and try again.") unless env_set
      puts "Connecting to Zendesk..."
      @client = ZendeskAPI::Client.new do |config|
        config.url = "https://example.zendesk.com/api/v2"
        config.username = USER
        config.token = TOKEN
      end
      puts "Connected as #{@client.current_user[:name]}"
    end

    def get_ticket(ticket_id = 'nil')
      return unless ticket_id
      @client.tickets.find(:id => ticket_id)
    end
  end

  class JiraIssue
    def initialize
    end
  end

  class Zap
    
    def init(ticket_id, connector)
      Zit::Error.new("Not a git repository") unless File.directory?(".git")
      puts "Found .git"
      @g = Git.open(Dir.pwd)
      checkout_master
      begin
        name = @g.config('github.user')
      rescue Git::GitExecuteError
        puts "Git name not set! Using dooby..."
        name = "dooby"
      end
      new_branch = branch_name(name, ticket_id)

      new_branch = "#{name}/zd#{ticket_id}"
      @g.branch(new_branch).checkout
      zt = Zit::ZendeskTicket.new
      ticket = zt.get_ticket(ticket_id)
      ticket.comment = {:body => "A new branch has been created for this ticket. It should be named #{new_branch}."}
      ticket.comment.public = false
      puts "Creating ticket comment"
      ticket.save
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
