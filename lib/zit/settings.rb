require "YAML"
module Zit
  class Settings
    def initialize
      unless File.exists?("#{ENV['HOME']}/.zit")
        defaults = {:default_system => :zendesk, :last_branch=>nil, :last_system=>nil, :repsteps_tag=>"macro_1234"}
        File.open("#{ENV['HOME']}/.zit", "w"){|settings| settings.puts(defaults.to_yaml) }.close
      end
      settings = YAML.load(File.open("#{ENV['HOME']}/.zit"))
    end
  end
end
