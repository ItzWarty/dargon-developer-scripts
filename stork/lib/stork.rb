require 'git'
require_relative 'config'
require_relative 'util'

class Stork
   def prepare_deploy(args)
      release_channel = args[0]
      release_config = Config.load_release_channel_config(release_channel)

      is_expected_release = release_channel == release_config["name"]
      raise "Expected release channel #{release_channel}!" unless is_expected_release

      release_packages = release_config["packages"];
      package_configs = release_packages.map { |k, v| [k, Config.load_package_config(k)] }.to_h;

      package_configs.each do |key, value| validate_unchanged(key, value); end
      updated_packages = (package_configs.select do |key, value|
         release_packages[key] != check_package(key, value);
      end);

      return 0 if updated_packages.none?

      puts "Found #{updated_packages.size} updated packages:"
      release_packages.each do |key, value|
         new_version = updated_packages[key]["version"] if updated_packages[key]
         update_prefix = new_version ? "*" : " ";
         update_postfix = new_version ? "=> #{new_version}" : "";
         puts "#{update_prefix} #{key} #{value} #{update_postfix}"
      end
      puts ""

      puts "Preparing to deploy new release of #{release_channel}."

      prev_version = SemVer.parse(release_config["version"]);
      puts "Prev Version: #{prev_version}"

      guess_version = SemVer.new("#{prev_version.major}.#{prev_version.minor}.#{prev_version.patch+1}")
      new_version = prompt_semver("New version?", guess_version)

      release_config["version"] = new_version.to_s;
      updated_packages.each do |key, value| release_packages[key] = value["version"]; end
      Config.save_release_channel_config(release_channel, release_config)

      puts "Saved new release channel configuration."
   end

   def validate_unchanged(package_name, package_config)
      package_repo_path = Config.get_repository_path(package_config["repo"])
      git = Git.open(package_repo_path)
      raise "Repository #{package_repo_path} has local changes." if git.diff.any?
   end

   def check_package(package_name, package_config = nil)
      package_config = Config.load_package_config(package_name) unless package_config
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
            prev_version = SemVer.parse(package_config["version"]);
            puts "Prev Version: #{prev_version}"

            guess_version = SemVer.new("#{prev_version.major}.#{prev_version.minor}.#{prev_version.patch+1}")
            new_version = prompt_semver("New version?", guess_version)

            package_config["commit"] = git_commit
            package_config["version"] = new_version
            Config.save_package_config(package_name, package_config)
         end
         puts ""
      end
      return package_config["version"];
   end
end
