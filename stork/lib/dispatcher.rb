require_relative 'commit_processor'
require_relative 'constants'
require_relative 'bundle_operations'
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

   def commit(args)
      release_channel = args[0]
      CommitProcessor.new(@deploy, @stage).process_channel(release_channel)
   end
end
