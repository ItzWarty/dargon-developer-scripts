require 'json'

class Constants
   def self.deploy_path() ENV['DARGON_STORK_DEPLOY_CONFIG_DIR']; end
   def self.stage_path() ENV['DARGON_STORK_STAGE_DIR']; end
   def self.nest_path() ENV['NEST_DIR']; end
   def self.repos_path() ENV['DARGON_REPOSITORIES_DIR']; end
end
