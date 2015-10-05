require_relative 'commit_processor'
require_relative 'constants'
require_relative 'bundle_staging_processor'
require_relative 'release_staging_processor'
require_relative 'storage'

class Dispatcher
   def initialize
      @deploy = Storage.new(Constants.deploy_path)
      @stage = Storage.new(Constants.stage_path)
   end

   def dispatch(args)
      command = args[0]
      arguments = args.drop(1)

      send(command, arguments)
   end

   def reset()
      @stage.clear()
   end

   def stage(args)
      what = args[0];
      send("stage_#{what}", args.drop(1));
   end

   def stage_bundle(args)
      bundle_name = args[0]
      BundleStagingProcessor.new(@deploy, @stage).process_bundle(bundle_name)
   end

   def stage_release(args)
      release_name = args[0];
      ReleaseStagingProcessor.new(@deploy, @stage).process(release_name);
   end

   def commit(args)
      release_channel = args[0]
      CommitProcessor.new(@deploy, @stage).process_channel(release_channel)
   end
end
