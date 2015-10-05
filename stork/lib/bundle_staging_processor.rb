require 'git'
require 'set'
require_relative 'constants'
require_relative 'util'

class BundleStagingProcessor
   def initialize(deploy, stage)
      @deploy = deploy
      @stage = stage
   end

   def process(bundle_name)
      bundle_resource_name = build_bundle_path(bundle_name);

      bundle_config = @deploy.get(bundle_resource_name)
      assert_equals(bundle_config.name, bundle_name)

      changed_packages = get_changed_packages(bundle_config);
      stage_changed_packages(changed_packages)

      if yesno("Bump #{bundle_name}?")
         bump_and_stage_bundle(bundle_name, bundle_resource_name, bundle_config);
      end

      puts "Done!"
   end

   def process_package_internal(package)
      package_repo = Git.open "#{Constants.repos_path}/#{package.repo}"
      current_commit = package_repo.object('HEAD').sha

      return false if package.commit == current_commit

      print "Package #{package.name} Commit #{package.commit[0...8]} => Commit #{current_commit[0...8]}! "

      return false unless yesno("Bump package?")

      package_version = SemVer.parse(package.version)
      suggested_version = SemVer.new("#{package_version.major}.#{package_version.minor}.#{package_version.patch+1}")
      new_version = prompt_semver("New package version?", suggested_version)

      package.commit = current_commit
      package.version = new_version

      egg_path = "#{Constants.nest_path}/#{package.name}"
      IO.write("#{egg_path}/version", package.version)

      true
   end

   def get_changed_packages(bundle_config)
      result = Set.new

      bundle_config.packages.to_h.each do |package_name, deployed_version|
         package = @deploy.get(build_package_path(package_name))
         if process_package_internal(package) || (package.version != deployed_version)
            changed_packages.add package
         end
      end

      result
   end

   def stage_changed_packages(bundle_config, changed_packages)
      if changed_packages.none?
         print 'No dependencies changed. There is nothing to stage.'
         return 0
      end

      puts "Updated packages: #{changed_packages.map { |p| p.name }.join ', '}"

      changed_packages.each do |package|
         puts "Bumping #{channel_name} to latest version of #{package.name} (#{package.version})."
         @stage.put(build_package_path(package.name), package)
         bundle_config.packages[package.name] = package.version
      end
   end

   def bump_and_stage_bundle(bundle_name, bundle_resource_name, bundle_config)
      channel_version = SemVer.parse(bundle_config.version)
      suggested_version = SemVer.new("#{channel_version.major}.#{channel_version.minor}.#{channel_version.patch+1}")
      new_version = prompt_semver("New package version?", suggested_version)
      bundle_config.version = new_version.to_s

      puts "Generating '#{bundle_config.name}' directory in nest..."
      egg_dir = "#{Constants.nest_path}/#{bundle_config.name}"
      Dir.mkdir egg_dir unless File.exists?(egg_dir)

      packages_content = (bundle_config.packages.to_h.map do |package_name, package_version|
         "#{package_name} #{package_version}"
      end).join("\n")

      IO.write("#{egg_dir}/PACKAGES", packages_content)

      @stage.put(bundle_config.name, config)
   end

   def build_bundle_path(bundle_name)
       "#{Constants.bundles_dir_name}/#{bundle_name}";
   end

   def build_package_path(package_name)
      "#{Constants.packages_dir_name}/#{package_name}";
   end
end
