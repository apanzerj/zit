module Zit
  class Settings
    DEFAULTS = {
        :default_system               => :zendesk,
        :last_branch                  => nil,
        :last_system                  => nil,
        :repsteps_tag                 => "macro_1234",
        :include_repsteps_by_default  => true,
        :zendesk_url                  => nil,
        :jira_url                     => nil,
        :settings_version             => 1.0
      }

    def initialize(system=nil)
      write_settings_file!(true) unless File.exists?("#{ENV['HOME']}/.zit")
      @settings = Psych.load(File.open("#{ENV['HOME']}/.zit"))
      @settings
    end
    
    def get(setting)
      return @settings[setting.to_sym]
    end

    def update_setting(setting_name, value)
      @settings[setting_name] = value
      write_settings_file!(false)
    end

    def update_settings(settings_hash)
      @settings.merge!(settings_hash)
      write_settings_file!(false)
    end

    def write_settings_file!(defaults = true)
      File.open("#{ENV['HOME']}/.zit", "w"){|settings| settings.puts(Psych.dump(defaults ? DEFAULTS : @settings)) }
    end
  end
end
