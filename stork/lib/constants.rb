require 'json'

class Constants
   def self.deploy_path() ENV['DARGON_STORK_DEPLOY_CONFIG_DIR']; end
   def self.stage_path() ENV['DARGON_STORK_STAGE_DIR']; end
   def self.nest_path() ENV['NEST_DIR']; end
   def self.repos_path() ENV['DARGON_REPOSITORIES_DIR']; end
   def self.bundles_dir_name() "bundles"; end
   def self.channels_dir_name() "channels"; end
   def self.packages_dir_name() "packages"; end
   def self.releases_dir_name() "releases"; end
end
