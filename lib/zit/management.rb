module Zit
  class Management
    def initialize(options = {}, settings)
      @options = options
      @settings = settings
      
      # Options = { 
      #   :system => [jira|zendesk]
      #   :project => 
      #   :foreign_key =>
      #   }
      
      #Validate ENV and Options
      options_validation(options)
      Zit::Error.new("There was an error configuring the client.") unless set_client
    end

    def set_client
      case @options[:system]
      when :zendesk
        env_set = (TOKEN.is_a?(String) && TOKEN.size > 0) && (USER.is_a?(String) && USER.size > 0)
        Zit::Error.new("Unable to locate the zendesk_token and zendesk_user environment variables. Please set them and try again.") unless env_set
        puts "Connecting to Zendesk..."
        @client = ZendeskAPI::Client.new do |config|
          config.url = @settings.get("zendesk_url")
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
      @options[:branch_name] ||= "#{username}/#{@options[:project]}_#{@options[:foreign_key]}" if @options[:system] == :jira
      @options[:branch_name]
    end

    def ping_back(msg)
      @options[:system] == :zendesk ? zendesk_pingback(msg) : jira_pingback(msg)
    end

    def ready
      if @options[:system] == :zendesk
        ticket = @options[:client].tickets.find(:id => @options[:foreign_key])
        rep_steps = get_repsteps(ticket)
      elsif @options[:system] == :jira
        issue = @options[:client].get_issue("#{@options[:project]}-#{@options[:foreign_key]}")
        comments = issue["fields"]["comment"]["comments"]
        rep_steps = (pick_comment(comments) || "Place a brief description here.")
      end
      link = "#{pr_link}#{@options[:current_branch]}"
      puts "open #{link}?pull_request[title]=#{@options[:system] == :zendesk ? "ZD" : "#{@options[:project]}-"}#{@options[:foreign_key]}&pull_request[body]=#{CGI.escape(rep_steps)}"
    end

    def pick_comment(comments)
      step = -1
      until (0..comments.size-1).include?(step)
        puts "Would you like to choose a comment from the issue as a description for your PR?"
        comments.each_index do |n|
          puts "#{n}. #{comments[n]["body"].inspect}"
        end
        print "(N)o, #:"
        step = gets.chomp
        step = Integer(step) unless step.to_s.downcase == "no"
        return nil if step.to_s.downcase == "no"
      end
      comments[step]["body"]
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

    def get_repsteps(ticket)
      macro_tag = @settings.get("repsteps_tag")
      audits = ticket.audits.fetch
      aud = audits.detect do |audit|
        next unless audit.events.map(&:type).include?("Change")
        next unless audit.events.map(&:field_name).include?("tags")
        next unless audit.events.map(&:value).join(" ").include?(macro_tag)
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
  end
end
