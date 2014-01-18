require "zit/version"
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

  class JiraClient
    include HTTParty
    JIRA_URI = "https://zendesk.atlassian.net/rest/api/latest"

    def initialize
      response = self.class.get("#{JIRA_URI}/dashboard", :basic_auth => self.auth )
      puts response.code
      self
    end

    def auth
      return { :username => JIRA_USER, :password => JIRA_PASS }
    end

    def get_issue(issue)
      self.class.get("#{JIRA_URI}/issue/#{issue}", :basic_auth => self.auth)
    end

    def add_comment_to_issue(message, issue)
#      post_options = {:body => {:body => message },}
      response = self.class.post("#{JIRA_URI}/issue/#{issue}/comment", :body=>{:body => message.to_s}.to_json, :headers => {'content-type'=>'application/json'}, :basic_auth => self.auth)
      puts response.code
    end
  end

  
  class Management
    def initialize(options = {})
      @options = options
      # Options = { 
      #   :system => [jira|zendesk]
      #   :project => 
      #   :foreign_key =>
      #   }
      
      #Validate ENV and Options
      valid = options_validation(options)
      Zit::Error.new("There was an error configuring the client.") unless set_client
    end

    def set_client
      case @options[:system]
      when :zendesk
        env_set = (TOKEN.is_a?(String) && TOKEN.size > 0) && (USER.is_a?(String) && USER.size > 0)
        Zit::Error.new("Unable to locate the zendesk_token and zendesk_user environment variables. Please set them and try again.") unless env_set
        puts "Connecting to Zendesk..."
        @client = ZendeskAPI::Client.new do |config|
          config.url = "https://example.zendesk.com/api/v2"
          config.username = USER
          config.token = TOKEN
        end
        puts "Connected as #{@client.current_user[:name]}"
        @options[:client] = @client
        true
      when :jira
        @options[:client] = JiraClient.new()
        true
      end
    end

    def options_validation(options)
      puts options.inspect
      begin
        Zit::Error.new("Invalid system...") if options[:system] != :zendesk && options[:system] != :jira
        case options[:system]
        when :zendesk
          Zit::Error.new("No ticket number provided!") if options[:foreign_key].nil?
        when :jira
          Zit::Error.new("No jira project!") if options[:project].nil?
          Zit::Error.new("No issue id!") if options[:foreign_key].nil?
        end
        true
      rescue NoMethodError
        Zit::Error.new("Nil Erorr")
      end
    end
    
    def branch_name(username)
      @options[:branch_name] ||= "#{username}/zd#{@options[:foreign_key]}" if @options[:system] == :zendesk
      @options[:branch_name] ||= "#{@options[:project]}_#{@options[:foreign_key]}" if @options[:system] == :jira
      @options[:branch_name]
    end

    def system_name
      @options[:system].to_s
    end

    def ping_back
      @options[:system] == :zendesk ? zendesk_pingback : jira_pingback
    end

    def zendesk_pingback
      ticket = @options[:client].tickets.find(:id => @options[:foreign_key].to_i)
      ticket.comment = {:body => "A new branch has been created for this ticket. It should be named #{@options[:branch_name]}."}
      ticket.comment.public = false
      puts "Creating ticket comment"
      ticket.save
    end

    def jira_pingback
      issue = "#{@options[:project]}-#{@options[:foreign_key]}"
      @options[:client].add_comment_to_issue("A branch for this issue has been created. It should be named #{@options[:branch_name]}.", issue)
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
        puts "Git name not set! Using dooby..."
        name = "dooby"
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
