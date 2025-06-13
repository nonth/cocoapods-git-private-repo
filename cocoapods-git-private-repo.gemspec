# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-git-private-repo/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-git-private-repo'
  spec.version       = CocoapodsGitPrivateRepo::VERSION
  spec.authors       = ['Nonthawat Srichad']
  spec.email         = ['nonthz@gmail.com']
  spec.description   = %q{A CocoaPods plugin that enhances Git downloader to support SSH private key authentication for private repositories. This plugin allows specifying a private key file path directly in your Podfile or through a JSON configuration file.}
  spec.summary       = %q{CocoaPods plugin for authenticating with private Git repositories using SSH private keys.}
  spec.homepage      = 'https://github.com/nonth/cocoapods-git-private-repo'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
