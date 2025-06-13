module Pod
  module Downloader
    class GitPrivateRepoDownloader < Git
      def initialize(target_path, url, options)
        super(target_path, url, options)

        # Check if a JSON configuration file exists with private key mappings
        json_config_path = 'keys.json'

        puts "file path: #{json_config_path}"

        # Only proceed with JSON processing if the file exists
        return unless File.exist?(json_config_path)
        
        begin
          require 'json'
          private_key_configs = JSON.parse(File.read(json_config_path))

          # Find a matching URL in the array of objects and no private_key_path is already set
          if !options[:private_key_path] && private_key_configs.is_a?(Array)
            matching_config = private_key_configs.find { |config| config["url"] == url }
            
            if matching_config && matching_config["key_path"]
              options[:private_key_path] = matching_config["key_path"]
            end
          end
        end
      end

      def execute_command(executable, command, raise_on_failure = false)
        puts "Executing command: #{executable} #{command.inspect}"
        puts "Options: #{self.options.inspect}"

        if executable == 'git' && options[:private_key_path]
          private_key = options[:private_key_path]
          
          command = command + ['-c', "core.sshCommand=ssh -i #{private_key}"]
        end
        
        super(executable, command, raise_on_failure)
      end
    end
  end
end