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

  class Options
    help
  end

  class Help
    header Crane::DESCRIPTION
  end
end
