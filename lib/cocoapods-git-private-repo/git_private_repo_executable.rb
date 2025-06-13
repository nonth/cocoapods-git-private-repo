require 'cocoapods'
require 'json'

module Pod
  # Monkey patch for the Executable module to handle SSH keys
  module Executable
    class << self
      alias_method :original_execute_command, :execute_command
      alias_method :original_capture_command, :capture_command
      
      # Override execute_command to handle SSH keys for git commands
      def execute_command(executable, command, raise_on_failure = true)
        # Only apply SSH key for git commands
        if executable.to_s == 'git'
          # Check if a private key should be used for this git command
          private_key_path = find_private_key_for_command(command)
          
          if private_key_path
            UI.message("Using private key: #{private_key_path} for git command") if Config.instance.verbose?
            
            bin = which!(executable)
            command = command.map(&:to_s)
            full_command = "#{bin} #{command.join(' ')}"
            
            if Config.instance.verbose?
              UI.message("$ #{full_command} (with SSH key)")
              stdout = Indenter.new(STDOUT)
              stderr = Indenter.new(STDERR)
            else
              stdout = Indenter.new
              stderr = Indenter.new
            end
            
            # Create environment with SSH key setting
            env = { "GIT_SSH_COMMAND" => "ssh -i #{private_key_path} -o IdentitiesOnly=yes" }

            UI.message("Executing command environment: #{env.inspect}") if Config.instance.verbose?
            
            require 'open3'
            status = nil
            
            # Execute with environment
            Open3.popen3(env, bin, *command) do |i, o, e, t|
              reader_threads = []
              reader_threads << reader(o, stdout)
              reader_threads << reader(e, stderr)
              i.close
              
              status = t.value
              
              o.flush
              e.flush
              sleep(0.01)
              
              # Wait for reader threads to complete
              reader_threads.each(&:join)
            end
            
            stdout = stdout.join
            stderr = stderr.join
            output = stdout + stderr

            unless status.success?
              if raise_on_failure
                raise Informative, "#{full_command}\n\n#{output}"
              else
                UI.message("[!] Failed: #{full_command}".red)
              end
            end
            
            return output
          end
        end
        
        # Fall back to original implementation for non-git commands
        # or git commands that don't need SSH keys
        original_execute_command(executable, command, raise_on_failure)
      end
      
      # Override capture_command to handle SSH keys for git commands
      def capture_command(executable, command, capture: :merge, env: {}, **kwargs)
        # Only apply SSH key for git commands
        if executable.to_s == 'git'
          # Check if a private key should be used for this git command
          private_key_path = find_private_key_for_command(command)
          
          if private_key_path
            UI.message("Using private key: #{private_key_path} for git command (capture)") if Config.instance.verbose?
            
            # Add SSH key setting to the environment
            git_ssh_cmd = "ssh -i #{private_key_path} -o IdentitiesOnly=yes"
            ssh_env = { "GIT_SSH_COMMAND" => git_ssh_cmd }
            
            # Merge with any existing environment variables
            env = env.merge(ssh_env)
            
            UI.message("Executing capture_command with environment: #{env.inspect}") if Config.instance.verbose?
          end
        end
        
        # Call the original method with possibly modified environment
        original_capture_command(executable, command, capture: capture, env: env, **kwargs)
      end
    
      # Override capture_command! to use our overridden capture_command
      def capture_command!(executable, command, **kwargs)
        capture_command(executable, command, **kwargs).tap do |result|
          result = Array(result)
          status = result.last
          unless status.success?
            output = result[0..-2].join
            
            # If this is a git command that might have used a private key
            if executable.to_s == 'git'
              private_key_path = find_private_key_for_command(command)
              if private_key_path
                error_message = enhance_ssh_error_message(output, private_key_path)
                raise Informative, "#{executable} #{command.join(' ')}\n\n#{error_message}".strip
              end
            end
            
            # Default error handler
            raise Informative, "#{executable} #{command.join(' ')}\n\n#{output}".strip
          end
        end
      end
    
    # Helper method to determine if a private key should be used
    def find_private_key_for_command(command)
      # Extract repository URL from git commands
      repo_url = extract_repo_url_from_command(command)

      return nil unless repo_url

      # Find keys.json in standard locations
      json_config_path = find_json_config_path()

      return nil unless json_config_path && File.exist?(json_config_path)
      
      begin
        private_key_configs = JSON.parse(File.read(json_config_path))
        
        # Find a matching URL in the configuration
        if private_key_configs.is_a?(Array)
          matching_config = private_key_configs.find { |config| config["url"] == repo_url }

          return matching_config["key_path"] if matching_config && matching_config["key_path"]
        end
      rescue => e
        UI.warn "Error reading keys.json: #{e.message}" if Config.instance.verbose?
      end
      
      nil
    end

    # Get the path to the keys.json configuration file
    # Searches in several standard locations related to the Podfile
    def find_json_config_path
      # First, look in the current directory
      return 'keys.json' if File.exist?('keys.json')
      
      # Get the Podfile path
      podfile_path = find_podfile_path
      return nil unless podfile_path
      
      # Look for keys.json next to the Podfile
      podfile_dir = File.dirname(podfile_path)
      config_next_to_podfile = File.join(podfile_dir, 'keys.json')
      return config_next_to_podfile if File.exist?(config_next_to_podfile)
      
      # Also check in the .cocoapods directory if it exists
      cocoapods_dir = File.join(podfile_dir, '.cocoapods')
      if Dir.exist?(cocoapods_dir)
        config_in_cocoapods = File.join(cocoapods_dir, 'keys.json')
        return config_in_cocoapods if File.exist?(config_in_cocoapods)
      end
      
      # Finally, check user's home directory
      home_config = File.expand_path('~/.cocoapods/keys.json')
      return home_config if File.exist?(home_config)
      
      # Could not find keys.json
      nil
    end
    
    # Find the path to the Podfile in the current project
    def find_podfile_path
      # First try the Pod::Config singleton if it exists and is initialized
      begin
        if Pod.const_defined?(:Config) && !Pod::Config.instance.nil? && Pod::Config.instance.installation_root
          podfile_path = File.join(Pod::Config.instance.installation_root, 'Podfile')
          return podfile_path if File.exist?(podfile_path)
        end
      rescue => e
        puts "Error accessing Pod::Config: #{e.message}" if Config.instance.verbose?
      end
      
      # If that fails, try searching up from the current directory
      current_dir = Dir.pwd
      while current_dir != '/'
        podfile_path = File.join(current_dir, 'Podfile')
        return podfile_path if File.exist?(podfile_path)
        current_dir = File.dirname(current_dir)
      end
      
      # Also try all parent directories of the repo being cloned if we're in a git command
      if defined?(@repo_path) && @repo_path
        current_dir = File.dirname(@repo_path)
        while current_dir != '/'
          podfile_path = File.join(current_dir, 'Podfile')
          return podfile_path if File.exist?(podfile_path)
          current_dir = File.dirname(current_dir)
        end
      end
      
      nil
    end
    
    # Extract repository URL from git commands like clone, fetch, etc.
    def extract_repo_url_from_command(command)
      # Common git commands that include repository URLs
      if command.include?('clone')
        # git clone URL [DIR]
        idx = command.index('clone')
        repo_url = command[idx + 1] if idx && command.size > idx + 1
        
        # Store the destination directory for potential Podfile lookup later
        if idx && command.size > idx + 2
          @repo_path = command[idx + 2]
        end
        
        return repo_url
      elsif command.include?('fetch') || command.include?('pull')
        # Find the path parameter in the command
        path = nil
        
        # Look for directory parameter (git -C path fetch/pull)
        if c_idx = command.index('-C')
          if c_idx + 1 < command.size
            path = command[c_idx + 1]
          end
        end

        return nil unless path

        # Fetch the origin URL from git config using the path
        return get_origin_url(path)
      end
      
      nil
    end
    
    # Get the origin URL from git config
    def get_origin_url(path = nil)
      # Try to get the origin URL from the git config
      begin
        if path && File.directory?(path)
          # If we have a path, use it to get the remote URL
          url_command = "git -C \"#{path}\" config --get remote.origin.url"
        else
          # Otherwise use the current directory
          url_command = "git config --get remote.origin.url"
        end
        
        result = `#{url_command}`.strip

        return result unless result.empty?
      rescue => e
        puts "Error getting origin URL: #{e.message}" if Config.instance.verbose?
        nil
      end
    end
    
    # This is the original reader method from Pod::Executable
    def reader(input, output)
      Thread.new do
        buf = ''
        begin
          loop do
            buf << input.readpartial(4096)
            loop do
              string, separator, buf = buf.partition(/[\r\n]/)
              if separator.empty?
                buf = string
                break
              end
              output << (string << separator)
            end
          end
        rescue EOFError, IOError
          output << (buf << $/) unless buf.empty?
        end
      end
    end
    end # end of class << self
  end # end of module Executable
end # end of module Pod
