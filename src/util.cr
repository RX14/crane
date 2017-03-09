module Crane::Util
  record ApplicationDirectory,
    config : String,
    data : String,
    cache : String

  def self.get_application_dirs(name = nil)
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

  def self.ensure_application_dirs(name)
    dirs = get_application_dirs(name)

    Dir.mkdir(dirs.config)
    Dir.mkdir(dirs.data)
    Dir.mkdir(dirs.cache)

    dirs
  end

  def self.which(name, path = ENV["PATH"]?)
    return unless path

    path.split(File::PATH_DELIMITER).each do |path|
      executable = File.join(path, name)
      return executable if File.exists?(executable)
    end
  end

  def self.run(command, *args, workdir : String? = nil)
    Process.run(which(command), args, chdir: workdir)
  end
end
