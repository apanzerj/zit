require "zit/version"
require "git"

module Zit
  class Error
    def initialize(msg)
      puts "Error: #{msg}"
      exit
    end
  end

  class Zap
    
    def init
      Zit::Error.new("Not a git repository") unless File.directory?(".git")
      puts "Found .git"
      g = Git.open(Dir.pwd)
      puts "Attempting to switch to master..."
      master = g.branches[:master]
      Zit::Error.new("Couldn't find branch master! #{master.inspect}") unless master
      
      

    end

  end
end
