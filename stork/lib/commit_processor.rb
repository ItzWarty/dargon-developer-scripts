require 'httparty'
require 'net/scp'
require 'net/ssh'
require 'set'
require_relative '../../stork/user/config'

class CommitProcessor
   def initialize(deploy, stage)
      @deploy = deploy
      @stage = stage
   end

   def process_channel(channel_name)
      config = @stage.get(channel_name)

      updated_packages = Set.new
      config.packages.each do |package_name, package_version|
         package = @stage.get(build_package_key(package_name))
         updated_packages.add(package) if package
      end

      puts 'Checking staged channel for remote conflicts...'
      check_remote_conflicts(config, config);

      puts 'Checking staged packages for remote conflicts...'
      updated_packages.each do |package| check_remote_conflicts(config, package); end

      puts 'Running predeploy commands...'
      updated_packages.each do |package| predeploy(package); end
      puts ""

      puts 'Deploying staged packages to remote...'
      remote = REMOTES[config.remote]
      Net::SSH.start(remote['remote_ip'], remote['remote_user'], :keys => remote['remote_key']) do |session|
         scp_client = Net::SCP.new(session)
         updated_packages.each do |package| deploy_to_remote(config, package, scp_client, remote['remote_nest_root']); end
      end
   end

   def check_remote_conflicts(config, entity)
      entity_full_name = get_entity_full_name(entity)
      entity_url = "#{config.remote}/#{entity_full_name}"
      req = HTTParty.get(entity_url)
      raise "Remote entity '#{entity_full_name}' already exists!" if req.code != 404
   end

   def predeploy(package)
      return 1 unless package.predeploy
      puts ""
      puts "Predeploy #{package.name}:"
      package.predeploy.to_h.each do |key, value|
         self.send("predeploy_#{key}", value, package)
      end
   end

   def predeploy_sign(file_paths, package)
      SIGNING['pfx_password'] = prompt_password("Code Signing PFX Password?") unless SIGNING['pfx_password']

      puts "Signing #{package.name} files: #{file_paths.join ', '}"
      signtool = SIGNING['signtool_path']
      pfx_path = SIGNING['pfx_path']
      pfx_password = SIGNING['pfx_password']
      timestamp_url = SIGNING['timestamp_url']
      egg_path = "#{Constants.nest_path}/#{package.name}"

      file_paths.each do |file_path|
         file_full_path = "#{egg_path}/#{file_path}"
         command = "_storkSignFile '#{file_full_path}' #{pfx_password}".strip

         signing_result = `bash -c ". ~/.bashrc && #{command}"`
         puts signing_result.strip
      end
   end

   def deploy_to_remote(config, package, scp_client, remote_nest_root)
      puts "Deploying #{package.name} to remote #{config.remote}."
      egg_path = "#{Constants.nest_path}/#{package.name}"
      remote_egg_path = "#{remote_nest_root}/#{package.name}-#{package.version}"
      scp_client.upload!(egg_path, remote_egg_path, :recursive => true);
   end

   def build_package_key(package_name) "packages/#{package_name}"; end
   def get_entity_full_name(entity) "#{entity.name}-#{entity.version}"; end
end