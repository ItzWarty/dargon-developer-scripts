require 'sem_ver'
require_relative 'constants'
require_relative 'storage'

class ChannelOperations
   def initialize(deploy, stage)
      @deploy = deploy
      @stage = stage
   end

   def try_bump(release, channel, version)
      channel_resource_path = build_channel_path(release, channel)
      channel_config = @deploy.get(channel_resource_path)
      raise "Unknown release/channel specified." unless channel_config

      old_version = SemVer.parse(channel_config.version)
      if (old_version > version)
         return unless yesno("Attempted to bump #{release}/#{channel} to version #{version} but deployed version is greater: #{old_version}. Continue?")
      end

      channel_config.version = version.to_s

      @stage.put(channel_resource_path, channel_config)
      puts "Bumped #{release}/#{channel} version #{old_version} => #{version}."
   end

   def build_channel_path(release, channel)
      "#{Constants.channels_dir_name}/#{release}/#{channel}"
   end
end
