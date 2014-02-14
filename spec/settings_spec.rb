#!/usr/bin/env ruby -wKU
require "spec_helper"
require_relative '../lib/zit/settings.rb'

def setup
    ENV.stub(:[]).with("HOME").and_return("foo")
    settings_file = double("File")
    File.stub(:open).with("foo/.zit").and_return(settings_file)
    settings_hash = Zit::Settings::DEFAULTS
    Psych.stub(:load).with(settings_file).and_return(settings_hash)
end

describe Zit::Settings::DEFAULTS do
  it "should have a skeletal settings defined" do
    Zit::Settings::DEFAULTS.should be_a_kind_of Hash
  end

  it "should have sensible defaults" do
    Zit::Settings::DEFAULTS[:settings_version].should be_a_kind_of(Float)
  end
end

describe Zit::Settings.new do
    before :each do
        setup
    end

    it "should create a new settings class" do
        File.stub(:exists?).with("foo/.zit").and_return("true")
        settings = Zit::Settings.new()
        settings.should be_an_instance_of Zit::Settings
    end

    it "should create a new file if one doesn't exist" do
        File.stub(:exists?).with("foo/.zit").and_return(false)
        File.stub(:open).with("foo/.zit", "w").and_return(true)
        settings = Zit::Settings.new
    end

    describe "foo" do
        before :each do
            setup
            File.stub(:exists?).with("foo/.zit").and_return(true)
            @settings = Zit::Settings.new()
            @settings.stub(:[]).with(:settings_version).and_return(1.0)
        end

        it "should return the right value" do
            @settings.get(:settings_version).should eq(1.0)
        end

        it "should convert non-symbol setting names" do
            @settings.get("settings_version").should eq(1.0)
        end
    end
end