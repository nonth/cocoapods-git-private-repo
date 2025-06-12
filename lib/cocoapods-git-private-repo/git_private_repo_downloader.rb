module Pod
  module Downloader
    class GitPrivateRepoDownloader < Git
      def self.options
        super + [:private_repo]
      end

      def self.preprocess_options(options)
        options[:private_repo] = true if options[:private_repo].nil?
        super(options)
      end

      def checkout_options
        options = super
        options[:private_repo] = true if options[:private_repo].nil?
        options
      end

      def download_file(full_filename)
        UI.puts("Downloading from private git repository: #{url}")
        super(full_filename)
      end
    end
  end
end