require 'git'
require 'set'
require_relative 'constants'
require_relative 'util'

class PackageOperations
   def initialize(deploy, stage, remote_client, hook_processor)
      @deploy = deploy
      @stage = stage
      @remote_client = remote_client
      @hook_processor = hook_processor
   end

   def try_stage(package_name)
      package_resource_name = build_package_path(package_name)
      @stage.remove(package_resource_name)
      config = @deploy.get(package_resource_name)
      return failure("Could not find package of name `#{package_name}` in deploy.") unless config

      repo = Git.open "#{Constants.repos_path}/#{config.repo}"
      current_commit = repo.object('HEAD').sha
      return failure("No changes to stage for package `#{package_name}` as repository `#{config.repo}` unchanged.") if config.commit == current_commit

      print "Package #{config.name} Commit #{config.commit[0...8]} => Commit #{current_commit[0...8]}! "
      return failure unless yesno("Bump package?")

      package_version = SemVer.parse(config.version)
      suggested_version = bump_patch(package_version)
      new_version = prompt_semver("New package version?", suggested_version)

      config.commit = current_commit
      config.version = new_version

      @stage.put(package_resource_name, config)
      return success("Successfully staged package `#{package_name}`.")
   end

   def try_commit(package_name)
      package_resource_name = build_package_path(package_name)
      package_config = @stage.get(package_resource_name)
      return failure("Could not find staged package of name #{package_name}.") unless package_config
      return failure("Remote package #{package_name} already deployed.") if @remote_client.deployed?(config.name, config.version)
      return failure("Predeploy hook(s) failed for package #{package_name}.") unless @hook_processor.process(package_config)

   end

   def build_package_path(package_name)
      "#{Constants.packages_dir_name}/#{package_name}";
   end
end
