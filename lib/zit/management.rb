module Zit
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

    def ping_back
      @options[:system] == :zendesk ? zendesk_pingback : jira_pingback
    end

    def ready
      @g = Git.open(Dir.pwd)
      @options[:current_branch] = @g.current_branch.to_s
      msg = "A pull request is being made for this branch."
      
      @options[:current_branch].match(/.*?\/zd(\d{1,8})/).size == 2 ? zendesk_ready : jira_ready
      if @options[:system] == :zendesk
        ticket = @options[:client].tickets.find(:id => @options[:foreign_key])
        rep_steps = get_repsteps(ticket)
      else
        rep_steps = "Place a brief description here."
      end
      link = "#{pr_link}#{@options[:current_branch]}"
      `open #{link}?pull_request[title]=ZD#{ticket_id}&pull_request[body]=#{CGI.escape(rep_steps)}`
    end

    def pr_link
      link = "#{BASE_REPO}/compare/master..."
    end

    # Zendesk methods

    def zendesk_pingback(msg)
      ticket = @options[:client].tickets.find(:id => @options[:foreign_key].to_i)
      ticket.comment = {:body => msg}
      ticket.comment.public = false
      puts "Creating ticket comment"
      ticket.save
    end

    def zendesk_ready
      @options[:connector] = :zendesk
      @options[:foreign_key] = @options[:current_branch].match(/.*?\/zd(\d{1,8})/)[1]
      zendesk_pingback("A pull request for your branch is being created")
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

    # Jira methods

    def jira_pingback(msg)
      issue = "#{@options[:project]}-#{@options[:foreign_key]}"
      response = @options[:client].add_comment_to_issue(msg, issue)
      puts "Jira issue updated!" if response == 201
    end

    def jira_ready
      @options[:connector]    = :jira
      mchdata = @options[:current_branch].match(/([A-Za-z].*?)_(\d.*?)/)
      @options[:project]      = mchdata[1]
      @options[:foreign_key]  = mchdata[2]
      jira_pingback("A pull request for your branch is being created")
    end
  end
end
