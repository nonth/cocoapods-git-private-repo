# CocoaPods Git Private Repo

A CocoaPods plugin that simplifies accessing private git repositories using SSH keys during pod installation. This plugin enables seamless authentication with private git repositories by automatically applying the correct SSH key for each repository.

## Features

- Automatically uses specified SSH keys for private git repositories
- Supports different SSH keys for different repositories
- Configurable via a simple JSON file
- Works with standard CocoaPods installation workflow

## Installation

```bash
$ gem install cocoapods-git-private-repo
```

## Usage

### Configuration File

For managing multiple private repositories with different keys, create a `keys.json` file in your project root with the following format:

```json
[
  {
    "url": "git@github.com:organization/repo-1.git",
    "key_path": "~/.ssh/id_rsa"
  },
  {
    "url": "git@github.com:organization/repo-2.git",
    "key_path": "~/.ssh/custom_key"
  }
]
```

The plugin will automatically:
1. Read the configuration file
2. Match repository URLs against the configuration
3. Use the appropriate SSH key for each repository

## How It Works

The plugin extends CocoaPods' Git downloader to:

1. Check for a repository URL match in your configuration
2. Override the git command to use the specified SSH key
3. Handle the authentication process automatically

This approach avoids the need to:
- Modify your SSH config for each repository
- Use different SSH clients for different repositories
- Manually handle key-based authentication

## Troubleshooting

If you encounter issues:

1. Ensure your SSH keys have the correct permissions
2. Verify the key paths in your configuration are correct and accessible
3. Check that the repository URLs in your configuration exactly match those in your Podfile
4. Enable verbose CocoaPods output for debugging:

```bash
$ pod install --verbose
```

## Development

1. Clone this repository
2. Run `bundle install` to install dependencies
3. Run `bundle exec rake spec` to run the tests
4. Create your feature branch (`git checkout -b my-new-feature`)
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE.txt file for details
