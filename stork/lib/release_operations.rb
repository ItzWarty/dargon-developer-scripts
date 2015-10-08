require 'git'
require 'sem_ver'
require 'set'
require_relative 'constants'
require_relative 'util'

class ReleaseOperations
   def initialize(deploy, stage, bundle_operations)
      @deploy = deploy
      @stage = stage
      @bundle_operations = bundle_operations
   end

   def try_stage(release_name)
      release_resource_path = build_release_path(release_name)
      @stage.remove(release_resource_path)
      release_config = @deploy.get(release_resource_path)
      release_config_modified = false

      release_config.bundles.to_h.each do |bundle_name, referenced_bundle_version_string|
         bundle_resource_name = build_bundle_path(bundle_name)

         is_staged = @bundle_operations.try_stage(bundle_name)
         bundle_config = is_staged ? @stage.get(bundle_resource_name)
                                   : @deploy.get(bundle_resource_name);

         referenced_bundle_version = SemVer.new(referenced_bundle_version_string)
         newest_bundle_version = SemVer.new(bundle_config.version);

         if referenced_bundle_version > newest_bundle_version
            raise "Invalid release for #{release_name} references bundle #{bundle_name} version #{referenced_bundle_version} when #{newest_bundle_version} is deployed."
         elsif referenced_bundle_version < newest_bundle_version
            puts "Release #{release_name} version #{release_config.version} references #{bundle_name} version #{referenced_bundle_version} but found version #{newest_bundle_version}."
            if yesno("Bump to newer bundle?")
               release_config.bundles[bundle_name] = newest_bundle_version.to_s;
               release_config_modified = true
            end
         end
      end

      if !release_config_modified
         puts "Did not find and update to newer bundles for release of `#{release_name}`; there is nothing to stage."
      else
         puts "Staged new release of `#{release_name}.`"
         @stage.put(release_resource_path, release_config);
      end
   end

   def build_release_path(release_name)
      "#{Constants.releases_dir_name}/#{release_name}"
   end

   def build_bundle_path(bundle_name)
      "#{Constants.bundles_dir_name}/#{bundle_name}"
   end
end
