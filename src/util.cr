module Crane::Util
  record ApplicationDirectory,
    config : String,
    data : String,
    cache : String

  def self.application_dirs(name = nil)
    # NOTE: See Haskell for windows implementations https://hackage.haskell.org/package/directory-1.3.1.0/docs/System-Directory.html#t:XdgDirectory
    config = ENV["XDG_CONFIG_HOME"]?
    config = File.expand_path("~/.config") unless config && config.starts_with?(File::SEPARATOR)
    config = File.join(config, name) if name

    data = ENV["XDG_DATA_HOME"]?
    data = File.expand_path("~/.local/share") unless data && data.starts_with?(File::SEPARATOR)
    data = File.join(data, name) if name

    cache = ENV["XDG_CACHE_HOME"]?
    cache = File.expand_path("~/.cache") unless cache && cache.starts_with?(File::SEPARATOR)
    cache = File.join(cache, name) if name

    ApplicationDirectory.new(config, data, cache)
  end

  def self.which(name, path = ENV["PATH"]?)
    raise "PATH not set" unless path

    path.split(Process::PATH_DELIMITER).each do |path|
      executable = File.join(path, name)
      return executable if File.exists?(executable)
    end
    raise "Executable `#{name}` not found in PATH"
  end

  def self.run(command, *args, workdir : String? = nil, stderr = false)
    stdout = String.build do |str|
      Process.run(which(command), args, chdir: workdir, output: str, error: stderr)
    end

    stdout.chomp
  end
end
