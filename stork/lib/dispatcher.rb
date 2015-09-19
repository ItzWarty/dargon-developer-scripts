require_relative 'constants'
require_relative 'staging_processor'
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

   def stage_deploy(args)
      release_channel = args[0]
      StagingProcessor.new(@deploy, @stage).process_channel(release_channel)
   end
end
