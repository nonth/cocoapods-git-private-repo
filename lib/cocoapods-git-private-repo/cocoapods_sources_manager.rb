require 'cocoapods-core/source'
require 'json'

module Pod
  module GitPrivateRepoSourceExtension
    def repo_git(args, include_error: false)      
      # Check for private key in configuration
      if private_key_path = find_private_key_for_repo        
        # Build git command with SSH key
        command = "GIT_SSH_COMMAND='ssh -i #{private_key_path} -o IdentitiesOnly=yes' git -C \"#{repo}\" " << args.join(' ')
        command << ' 2>&1' if include_error

        (`#{command}` || '').strip
      else
        # Use original implementation if no private key is found
        super(args, include_error: include_error)
      end
    end
    
    def update_git_repo(show_output = false)      
      # If we have a private key, use our custom implementation
      if private_key_path = find_private_key_for_repo        
        command = ['pull']
        command << '--progress' if show_output
        repo_git(command)
      else
        # Use original implementation if no private key is found
        super(show_output)
      end
    end
    
    private
    
    def find_private_key_for_repo
      # Check if a JSON configuration file exists with private key mappings
      json_config_path = 'keys.json'
      return nil unless File.exist?(json_config_path)
      
      private_key_configs = JSON.parse(File.read(json_config_path))
      
      # Find a matching repo URL in the configuration
      if private_key_configs.is_a?(Array)
        # Directly get git remote url from repo to avoid recursion
        repo_url = get_git_remote_url(repo)
        return nil unless repo_url
        
        matching_config = private_key_configs.find { |config| config["url"] == repo_url }
        return matching_config["key_path"] if matching_config && matching_config["key_path"]
      end
      
      nil
    end
    
    # Safely get the git remote URL directly without using Source#url
    def get_git_remote_url(repo_path)
      return nil unless repo_path
      
      # Use git directly to get URL from the repo config
      url_command = "git -C \"#{repo_path}\" config --get remote.origin.url"
      remote_url = `#{url_command}`.strip
      return remote_url unless remote_url.empty?
    end
  end
  
  # Prepend the module to Source to override methods
  Source.prepend(GitPrivateRepoSourceExtension)
end