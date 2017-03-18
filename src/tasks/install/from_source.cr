require "tempfile"
require "secure_random"
require "file_utils"
require "json"
require "colorize"

module Crane::Tasks
  private def self.ensure_crystal_sources
    dirs = Util.application_dirs("crane")
    crystal_source_dir = File.join(dirs.cache, "git", "crystal")

    begin
      if Dir.exists? crystal_source_dir
        STDERR.puts "#{"Updating".colorize.green} crystal source..."
        Util.run("git", "fetch", "--all", "--tags", workdir: crystal_source_dir, stderr: true)
      else
        STDERR.puts "#{"Downloading".colorize.green} crystal source..."
        Util.run("git", "clone", "https://github.com/crystal-lang/crystal", crystal_source_dir, stderr: true)
      end
    rescue ex
      FileUtils.rm_r(crystal_source_dir)
      raise ex
    end

    crystal_source_dir
  end

  private def self.temp_crystal_checkout(revision)
    base_clone_path = ensure_crystal_sources
    temp_clone_path = File.join(Tempfile.dirname, "crystal-checkout-#{SecureRandom.hex}")

    begin
      FileUtils.cp_r(base_clone_path, temp_clone_path)
      Util.run("git", "checkout", "-f", revision, workdir: temp_clone_path)

      # Assert the checkout worked
      current_rev = Util.run("git", "rev-list", "-1", "HEAD", workdir: temp_clone_path)
      target_rev = Util.run("git", "rev-list", "-1", revision, workdir: temp_clone_path)
      Util.assert current_rev == target_rev

      yield temp_clone_path
    ensure
      FileUtils.rm_r(temp_clone_path)
    end
  end

  # Installs a new crystal version to *version_manager* at *revision*.
  def self.install_crystal_from_source(version_manager, revision, *, release) : CrystalVersion
    temp_crystal_checkout(revision) do |repository|
      # Doubly ensure cleanliness
      Util.run("git", "clean", "-fdx", workdir: repository)
      Util.run("make", "clean", workdir: repository)

      # Make deps to allow bin/crystal execution
      Util.run("make", "deps", workdir: repository, stderr: true)

      # Get version information from compiler
      crystal_version, crystal_short_rev = get_crystal_version_and_sha(repository)

      # Assert returned sha is correct
      raise "BUG: No short rev returned" unless crystal_short_rev
      target_rev = Util.run("git", "rev-list", "-1", revision, workdir: repository)
      Util.assert target_rev.starts_with? crystal_short_rev

      STDERR.puts "#{"Installing".colorize.green} crystal #{crystal_version} [#{crystal_short_rev}]"
      version = version_manager.new_version(crystal_version, InstallMethod::Git)

      begin
        compile_env = {
          "CRYSTAL_CONFIG_VERSION" => crystal_version,
          "CRYSTAL_CONFIG_PATH"    => "lib:#{version.stdlib_path}",
          "CRYSTAL_CACHE_DIR"      => ".crystal",
        }
        compile_env["release"] = "true" if release

        STDERR.puts "  #{"Compiling".colorize.blue} crystal in #{release ? "release" : "debug"} mode..."
        Util.run("make", "crystal", workdir: repository, stderr: true, env: compile_env)
        FileUtils.cp(File.join(repository, ".build", "crystal"), version.crystal_path)

        # Copy stdlib
        STDERR.puts "  #{"Copying".colorize.blue} standard library..."
        FileUtils.cp_r(File.join(repository, "src"), version.stdlib_path)
      rescue ex
        version_manager.delete_version(version)
        raise ex
      end

      version
    end
  end

  def self.get_crystal_version_and_sha(repository)
    version_file = Tempfile.open("crane-version-sniffer") do |file|
      file.puts <<-FILE
        require "json"
        require "compiler/crystal/config"

        puts Crystal::Config.version_and_sha.to_json
        FILE
    end

    version_json = Util.run(File.join(repository, "bin", "crystal"), "run", version_file.path, workdir: repository)
    Tuple(String, String?).from_json(version_json)
  end
end
