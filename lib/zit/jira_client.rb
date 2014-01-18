require "httparty"
module Zit
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
      response = self.class.post("#{JIRA_URI}/issue/#{issue}/comment", :body=>{:body => message.to_s}.to_json, :headers => {'content-type'=>'application/json'}, :basic_auth => self.auth)
      response.code
    end
  end
end
