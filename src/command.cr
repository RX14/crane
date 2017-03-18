require "cli"

class Crane::Command < Cli::Supercommand
  version Crane::VERSION
  command_name "crane"

  class Install < Cli::Command
    class Options
      arg "version", required: true
      bool "--release", default: true, not: "--no-release"
    end

    def run
      version_manager = VersionManager.new(VersionManager.default_base_dir)
      Tasks.install_crystal_from_source(version_manager, options.version, release: options.release?)
    end
  end

  class Versions < Cli::Command
    def run
      version_manager = VersionManager.new(VersionManager.default_base_dir)
      version_manager.versions.each { |v| puts v.version }
    end
  end

  class Rimraf < Cli::Command
    class Options
      bool "--really"
    end

    def run
      exit! "Are you sure you want to wipe all data? Use --really" unless options.really?

      dirs = Util.application_dirs("crane")
      FileUtils.rm_rf dirs.config
      FileUtils.rm_rf dirs.data
      FileUtils.rm_rf dirs.cache
    end
  end

  class Completion < Cli::Command
    class Options
      string "--shell", any_of: %w(bash zsh), default: "bash"
    end

    def run
      case options.shell
      when "bash"
        puts Crane::Command.generate_bash_completion
      when "zsh"
        puts Crane::Command.generate_zsh_completion
      end
    end
  end

  before_initialize do
    Util.ensure_application_dirs
  end

  class Options
    help
    version
  end

  class Help
    header Crane::DESCRIPTION
  end
end
