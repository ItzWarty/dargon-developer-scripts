require_relative 'lib/dispatcher'
require_relative 'lib/util'

args = ARGV

if args[0] == '--skip-dialogs' || args[0] == '-s'
   $skip_dialogs = true
   args = args.drop(1)
end

Dispatcher.new().dispatch(args)
