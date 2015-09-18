require 'json'

class Config
   def self.load_for_release_channel(release_channel)
      path = "#{ENV["DARGON_STORK_DEPLOY_CONFIG_DIR"]}/#{release_channel}.json";
      return JSON.parse(IO.read(path));
   end
   def self.load_package_config(package_name)
      path = "#{ENV["DARGON_STORK_DEPLOY_CONFIG_DIR"]}/packages/#{package_name}.json";
      return JSON.parse(IO.read(path));
   end
   def self.save_package_config(package_name, package_config)
      path = "#{ENV["DARGON_STORK_DEPLOY_CONFIG_DIR"]}/packages/#{package_name}.json";
      json = JSON.pretty_generate(package_config);
      IO.write(path, json);
   end
   def self.get_repository_path(repository_name)
      return "#{ENV["DARGON_REPOSITORIES_DIR"]}/#{repository_name}";
   end
end
