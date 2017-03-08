require "./spec_helper"
require "yaml"

describe Crane do
  describe "VERSION" do
    it "matches the version in shards.yml" do
      version = YAML.parse(File.read(File.join(__DIR__, "..", "shard.yml")))["version"].as_s
      version.should eq(Crane::VERSION)
    end
  end

  describe "DESCRIPTION" do
    it "matches the description in shards.yml" do
      version = YAML.parse(File.read(File.join(__DIR__, "..", "shard.yml")))["description"].as_s.chomp
      version.should eq(Crane::DESCRIPTION)
    end
  end
end
