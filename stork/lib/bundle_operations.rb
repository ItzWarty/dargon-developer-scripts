require 'git'
require 'set'
require_relative 'constants'
require_relative 'package_operations'
require_relative 'util'

class BundleOperations
   def initialize(deploy, stage, package_operations)
      @deploy = deploy
      @stage = stage
      @package_operations = package_operations
   end

   def try_stage(bundle_name)
      bundle_resource_name = build_bundle_path(bundle_name);
      @stage.remove(bundle_resource_name)
      bundle_config = @deploy.get(bundle_resource_name)
      assert_equals(bundle_config.name, bundle_name)

      newer_packages = get_newer_packages(bundle_config);

      if (newer_packages.none?)
         puts "No dependencies of bundle #{bundle_name} changed. There is nothing to stage."
         return false
      end

      puts "Found #{newer_packages.size} updated dependencies for bundle `#{bundle_name}`:"
      newer_packages.each do |package|
         puts "\t#{package.name} #{bundle_config.packages[package.name]} => #{package.version}"
         bundle_config.packages[package.name] = package.version
      end
      return false unless yesno("Bump bundle #{bundle_name}?")

      bundle_version = SemVer.parse(bundle_config.version)
      suggested_version = bump_patch(bundle_version)
      new_version = prompt_semver("New bundle version?", suggested_version)

      bundle_config.version = new_version

      @stage.put(bundle_resource_name, bundle_config)
      puts "Successfully staged bundle `#{bundle_name}`."
      return true
   end

   def get_newer_packages(bundle_config)
      result = Set.new

      bundle_config.packages.to_h.each do |package_name, deployed_version|
         is_staged = @package_operations.try_stage(package_name)

         package = is_staged ? @stage.get(build_package_path(package_name))
                             : @deploy.get(build_package_path(package_name));

         result.add(package) if is_staged || (package.version != deployed_version)
      end

      result
   end

   def build_bundle_path(bundle_name)
       "#{Constants.bundles_dir_name}/#{bundle_name}";
   end

   def build_package_path(package_name)
      "#{Constants.packages_dir_name}/#{package_name}";
   end
end
