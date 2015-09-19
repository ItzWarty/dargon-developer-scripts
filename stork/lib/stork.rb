require 'httparty'
require 'git'
require 'net/http'
require 'net/scp'
require 'net/ssh'
require_relative 'config'
require_relative 'util'
require_relative '../user/remotes'

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

   def execute_deploy(args)
      release_channel = args[0]
      release_config = Config.load_release_channel_config(release_channel)
      release_packages = release_config["packages"]
      release_version = SemVer.parse(release_config["version"])
      release_remote = release_config["remote"]

      remote_config = REMOTES[release_remote];
      remote_ip = remote_config["remote_ip"]
      remote_user = remote_config["remote_user"]
      remote_key = remote_config["remote_key"]
      remote_nest_root = remote_config["remote_nest_root"]

      remote_session = Net::SSH.start(
        remote_ip, remote_user,
        :keys => remote_key);

      remote_scp_client = Net::SCP.new(remote_session);

      # Validate deploying stable version is above remote/stable
      print "Fetching remote version of #{release_channel}... "
      remote_channel_url = "#{release_remote}/#{release_channel}"
      remote_channel_pointer = HTTParty.get(remote_channel_url);
      remote_channel_version = SemVer.parse(remote_channel_pointer.split("-")[-1]);
      puts remote_channel_version;

      raise "Local (#{release_version}) <= Remote #{remote_channel_version}!" if release_version <= remote_channel_version;
      puts "Verified that local version > remote version!"
      puts

      nest_path = Config.get_nest_path();
      puts "Local nest directory: '#{nest_path}'."

      puts "Deploying eggs..."
      release_packages.each do |egg_name, egg_version_string|
         egg_version_parts = egg_version_string.split("=>");
         next if egg_version_parts.size == 1
         previous_egg_version = egg_version_parts[0];
         egg_version = egg_version_parts[-1];
         puts egg_name + " #{previous_egg_version} => #{egg_version}"
         egg_full_name = "#{egg_name}-#{egg_version}"

         # Update egg_path/version
         egg_path = "#{nest_path}/#{egg_name}";
         egg_version_path = "#{egg_path}/version"
         IO.write(egg_version_path, egg_version);

         # Validate that a conflicting remote egg doesn't alraedy exist
         remote_egg_path = "#{release_remote}/#{egg_full_name}";
         remote_egg_version_path = "#{remote_egg_path}/version";
         remote_egg_version_req = HTTParty.get(remote_egg_version_path);
         puts "Got response code #{remote_egg_version_req.code} when fetching #{remote_egg_version_path}."
         raise "Remote egg already exists" if remote_egg_version_req.code != 404
         puts "Successfully validated that remote egg doesn't exist!"

         # Deploy egg to remote server
         remote_egg_nest_path = "#{remote_nest_root}/#{egg_full_name}";
         puts "Uploading #{egg_path} to #{remote_egg_nest_path}";
         remote_scp_client.upload!(egg_path, remote_egg_nest_path, :recursive => true);
      end

      remote_session.close
   end
end
