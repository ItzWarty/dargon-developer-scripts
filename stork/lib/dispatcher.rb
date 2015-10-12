require 'sem_ver'
require_relative 'commit_processor'
require_relative 'constants'
require_relative 'bundle_operations'
require_relative 'channel_operations'
require_relative 'package_operations'
require_relative 'release_operations'
require_relative 'storage'

class Dispatcher
   def initialize
      @deploy = Storage.new(Constants.deploy_path)
      @stage = Storage.new(Constants.stage_path)

      @package_operations = PackageOperations.new(@deploy, @stage);
      @bundle_operations = BundleOperations.new(@deploy, @stage, @package_operations);
      @release_operations = ReleaseOperations.new(@deploy, @stage, @bundle_operations);
      @channel_operations = ChannelOperations.new(@deploy, @stage);
   end

   def dispatch(args)
      command = args[0]
      arguments = args.drop(1)

      send(command, arguments)
   end

   def reset(args)
      @stage.clear()
      puts "Reset stork stage."
   end

   def stage(args)
      what = args[0];
      send("stage_#{what}", args.drop(1));
   end

   def stage_package(args)
      package_name = args[0]
      @package_operations.try_stage(package_name)
   end

   def stage_bundle(args)
      bundle_name = args[0]
      @bundle_operations.try_stage(bundle_name)
   end

   def stage_release(args)
      release_name = args[0];
      @release_operations.try_stage(release_name);
   end

   def stage_channel(args)
      release_and_channel = args[0]
      release = release_and_channel.split("/")[0]
      channel = release_and_channel.split("/")[1]
      raise 'First argument should be of format release/channel' if "#{release}/#{channel}" != release_and_channel

      version = SemVer.parse(args[1])
      raise 'Second argument should be a semantic version' unless version.valid?

      @channel_operations.try_bump(release, channel, version);
   end

   def commit(args)
      what = args[0]
      send("commit_#{what}", args.drop(1))
   end

   def commit_all(args)
      @stage.enumerate_keys('packages').each {|key| commit_package([key.split('/').last] + args)}
      @stage.enumerate_keys('bundles').each {|key| commit_bundle([key.split('/').last] + args)}
      @stage.enumerate_keys('releases').each {|key| commit_release([key.split('/').last] + args)}
   end

   def commit_package(args)
      package_name = args[0]
      @package_operations.try_commit(package_name)
   end

   def commit_bundle(args)
      puts "Committing bundle #{args[0]}"
   end

   def commit_release(args)
      puts "Committing release #{args[0]}"
   end
end
