require 'git'
require_relative 'config'
require_relative 'util'

class Stork
   def check_packages(args)
      release_channel = args[0]
      release_config = Config.load_for_release_channel(release_channel)

      is_expected_release = release_channel == release_config["name"]
      raise "Expected release channel #{release_channel}!" unless is_expected_release

      release_packages = release_config["packages"];
      package_configs = release_packages.map { |k, v| [k, Config.load_package_config(k)] }.to_h;

      package_configs.each do |key, value| validate_unchanged(key, value); end
      package_configs.each do |key, value| check_package(key); end
   end

   def validate_unchanged(package_name, package_config)
      package_repo_path = Config.get_repository_path(package_config["repo"])
      git = Git.open(package_repo_path)
      raise "Repository #{package_repo_path} has local changes." if git.diff.any?
   end

   def check_package(package_name)
      puts "Checking Package '#{package_name}'"
      package_config = Config.load_package_config(package_name)
      package_repo = package_config["repo"];
      package_repo_path = Config.get_repository_path(package_repo)
      package_commit = package_config["commit"];

      git = Git.open(package_repo_path)

      git_commit = git.object('HEAD').sha
      package_updated = git_commit != package_config["commit"]

      if package_updated
         puts "Repository for package #{package_config["name"]} has changed."
         puts "   Previous Commit: #{package_commit}"
         puts "        New Commit: #{git.object('HEAD').sha}"
         puts ""
         should_bump_package = yesno "Bump Package?"

         if should_bump_package
            puts "Prev Version: #{package_config["version"]}"
            version = prompt_semver("New version?")
            package_config["commit"] = git_commit
            package_config["version"] = version
            Config.save_package_config(package_name, package_config)
         end
      end
      puts ""
   end
end
