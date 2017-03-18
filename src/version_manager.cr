require "file_utils"
require "json"

module Crane
  enum InstallMethod
    Git = 0
  end

  class CrystalVersion
    getter base_dir : String
    getter version : String
    getter install_method : InstallMethod

    def initialize(@base_dir, @version, @install_method)
      # Create base_dir and base_dir/bin
      FileUtils.mkdir_p(File.join(base_dir, "bin"))
    end

    def crystal_path
      File.join(base_dir, "bin", "crystal")
    end

    def shards_path
      File.join(base_dir, "bin", "shards")
    end

    def stdlib_path
      File.join(base_dir, "src")
    end

    def save
      File.open(File.join(base_dir, "meta.json"), "w") do |file|
        Mapper.new(version, install_method).to_json(file)
      end
    end

    def self.load(base_dir)
      File.open(File.join(base_dir, "meta.json")) do |file|
        mapper = Mapper.from_json(file)
        self.new(base_dir, mapper.version, mapper.install_method)
      end
    end

    struct Mapper
      def initialize(@version, @install_method)
      end

      JSON.mapping({
        version:        String,
        install_method: InstallMethod,
      })
    end
  end

  class VersionManager
    getter base_dir : String
    getter versions = Array(CrystalVersion).new

    def initialize(@base_dir)
      load_versions
    end

    def self.default_base_dir
      data_dir = Util.application_dirs("crane").data
      File.join(data_dir, "versions")
    end

    def new_version(version_name, install_method)
      version_base_dir = File.join(base_dir, "#{version_name}-#{install_method.to_s.downcase}")

      conflicting_version = versions.find { |v| v.base_dir == version_base_dir }
      raise VersionAlreadyRegisteredException.new(conflicting_version) if conflicting_version

      version = CrystalVersion.new(version_base_dir, version_name, install_method)
      version.save
      versions << version

      version
    end

    def delete_version(version)
      versions.delete version
      FileUtils.rm_r(version.base_dir)
    end

    private def load_versions
      return unless Dir.exists? base_dir

      Dir.foreach(base_dir) do |dir|
        next if {".", ".."}.includes? dir
        dir = File.join(base_dir, dir)

        begin
          versions << CrystalVersion.load(dir)
        rescue ex
          STDERR.puts "#{"Failed".colorize.red} to load version from #{dir}\n  #{ex.message}"
        end
      end
    end

    class VersionAlreadyRegisteredException < Exception
      getter conflicting_version : CrystalVersion

      def initialize(@conflicting_version)
        super("Crystal version already registered")
      end
    end
  end
end
