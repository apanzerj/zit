require "httparty"
require "zit/settings"

module Zit
  class JiraClient
    include HTTParty
    SETTINGS = Zit::Settings.new

    def initialize
      response = self.class.get("#{SETTINGS.get("jira_url")}/dashboard", :basic_auth => self.auth )
      self
    end

    def auth
      return { :username => JIRA_USER, :password => JIRA_PASS }
    end

    def get_issue(issue)
      self.class.get("#{SETTINGS.get("jira_url")}/issue/#{issue}", :basic_auth => self.auth)
    end

    def add_comment_to_issue(message, issue)
      response = self.class.post("#{SETTINGS.get("jira_url")}/issue/#{issue}/comment", :body=>{:body => message.to_s}.to_json, :headers => {'content-type'=>'application/json'}, :basic_auth => self.auth)
      response.code
    end
  end
end
