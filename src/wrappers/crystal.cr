require "../crane"

private def exit!(message)
  STDERR.puts message
  exit(10)
end

Crane::Util.ensure_application_dirs

if (first_arg = ARGV[0]?) && first_arg.starts_with?('@')
  version_name = first_arg[1..-1]
  ARGV.shift
else
  # TODO: global config
  exit! "no version specified"
end

dirs = Crane::Util.application_dirs("crane")

version_manager = Crane::VersionManager.new(Crane::VersionManager.default_base_dir)
version = version_manager.versions.find { |v| v.version == version_name }
exit! "Version #{version_name} not installed" unless version

crystal_path = ENV["CRYSTAL_PATH"]? || "lib:#{version.stdlib_path}"
Process.exec(version.crystal_path, args: ARGV, env: {
  "CRYSTAL_PATH"      => crystal_path,
  "CRYSTAL_CACHE_DIR" => File.join(dirs.cache, "crystal-cache", File.basename(version.base_dir)),
})
