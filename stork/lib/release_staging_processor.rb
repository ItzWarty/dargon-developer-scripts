require 'git'
require 'sem_ver'
require 'set'
require_relative 'constants'
require_relative 'util'

class ReleaseStagingProcessor
   def initialize(deploy, stage)
      @deploy = deploy
      @stage = stage
   end

   def process(release_name)
      release_resource_path = build_release_path(release_name)
      release_config = @deploy.get(release_resource_path)

      release_config.bundles.to_h.each do |bundle_name, referenced_bundle_version_string|
         referenced_bundle_version = SemVer.new(referenced_bundle_version_string)
         bundle_config = @stage.get(build_bundle_path(bundle_name));
         bundle_config = @deploy.get(build_bundle_path(bundle_name)) unless bundle_config
         deployed_bundle_version = SemVer.new(bundle_config.version);

         if referenced_bundle_version > deployed_bundle_version
            raise "Invalid release for #{release_name} references bundle #{bundle_name} version #{referenced_bundle_version} when #{deployed_bundle_version} is deployed."
         elsif referenced_bundle_version < deployed_bundle_version
            puts "Release #{release_name} version #{release_config.version} references #{bundle_name} version #{referenced_bundle_version} but found version #{deployed_bundle_version}."
            if yesno("Bump to newer package?")
               release_config.bundles[bundle_name] = deployed_bundle_version.to_s;
            end
         end
      end

      p release_config;
   end

   def build_release_path(release_name)
      "#{Constants.releases_dir_name}/#{release_name}"
   end

   def build_bundle_path(bundle_name)
      "#{Constants.bundles_dir_name}/#{bundle_name}"
   end
end
