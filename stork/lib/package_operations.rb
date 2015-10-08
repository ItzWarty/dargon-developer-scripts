require 'git'
require 'set'
require_relative 'constants'
require_relative 'util'

class PackageOperations
   def initialize(deploy, stage)
      @deploy = deploy
      @stage = stage
   end

   def try_stage(package_name)
      package_resource_name = build_package_path(package_name)
      @stage.remove(package_resource_name)
      config = @deploy.get(package_resource_name)
      if config == nil
         puts "Could not find package of name `#{package_name}` in deploy."
         return false
      end

      repo = Git.open "#{Constants.repos_path}/#{config.repo}"
      current_commit = repo.object('HEAD').sha
      if config.commit == current_commit
         puts "No changes to stage for package `#{package_name}` as repository `#{config.repo}` unchanged."
         return false
      end

      print "Package #{config.name} Commit #{config.commit[0...8]} => Commit #{current_commit[0...8]}! "
      return false unless yesno("Bump package?")

      package_version = SemVer.parse(config.version)
      suggested_version = bump_patch(package_version)
      new_version = prompt_semver("New package version?", suggested_version)

      config.commit = current_commit
      config.version = new_version

      @stage.put(package_resource_name, config)
      puts "Successfully staged package `#{package_name}`."
      true
   end

   def build_package_path(package_name)
      "#{Constants.packages_dir_name}/#{package_name}";
   end
end
