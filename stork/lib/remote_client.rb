require 'httparty'
require 'net/scp'
require 'net/ssh'

class RemoteClient
   def initialize(config)
      @config = config
   end

   def deployed?(entity_name, entity_version)
      entity_full_name = get_entity_full_name(entity_name, entity_version)
      entity_url = "#{@config.remote}/#{entity_full_name}"
      return HTTParty.get(entity_url) == 200
   end

   def get_entity_full_name(entity_name, entity_version)
      "#{entity_name}-#{entity_version}"
   end
end