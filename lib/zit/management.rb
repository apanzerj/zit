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
      response = @options[:client].add_comment_to_issue("A branch for this issue has been created. It should be named #{@options[:branch_name]}.", issue)
      puts "Jira issue updated!" if response == 201
    end
  end
end
