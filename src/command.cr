require "cli"

class Crane::Command < Cli::Supercommand
  version Crane::VERSION
  command_name "crane"

  class Install < Cli::Command
    def run
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
    dirs = Util.application_dirs("crane")

    Dir.mkdir(dirs.config) unless Dir.exists? dirs.config
    Dir.mkdir(dirs.data) unless Dir.exists? dirs.data
    Dir.mkdir(dirs.cache) unless Dir.exists? dirs.cache
  end

  class Options
    help
  end

  class Help
    header Crane::DESCRIPTION
  end
end