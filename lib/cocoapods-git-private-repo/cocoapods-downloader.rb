require 'cocoapods-git-private-repo/git_private_repo_downloader'

module Pod
  module Downloader
    class <<self
      alias_method :real_downloader_class_by_key, :downloader_class_by_key
    end

    def self.downloader_class_by_key
      original = self.real_downloader_class_by_key
      
      puts "CocoaPods Git Private Repo: Overriding downloader_class_by_key to use GitPrivateRepoDownloader"
      puts original.inspect
      original[:git] = GitPrivateRepoDownloader

      original
    end

  end
end