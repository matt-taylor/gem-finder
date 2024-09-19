# GemEnforcer

`GemEnforcer` is intended to ensure that your ruby scripts services or gems are using an acceptable version of specific gems. In the event that the gem is out of compliance, GemEnforcer can exit or raise an error before continuing.

## Inspiration

I build a lot of scripts that live locally and on other developers laptops. It is hard to ensure that they know when a new version of a critical gem has been realeased. With GemEnforcer, after upgrading, I can enforce the developer is using:
- One of the 3 most recently released versions of Sidekiq
- Within 3 minor versions of the most recently released Major version
- The most recent patch vesion of a current minor version
- And so many more combinations


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gem_enforcer'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install gem_enforcer

### Create a Configuration File

[Check out Configuration examples](examples)

### Configure the Gem

Prior to running the validation, you can set custom configurations to tailor the GemEnforcement experience

```ruby
GemEnforcer.configuration do |config|
  # TO use Git Tags, the access token must be provided
  # As a default it will check ENV["GITHUB_TOKEN"] or ENV["BUNDLE_GITHUB__COM"] if it is there
  # If not, it must be provided to use git tag
  config.github_access_token = "my_access_token"

  config.yml_config_path = "The path to your config file"
  config.logger = MyLoggerClass #TTY::Logger or Logger classes allowed
end
```

### Run Validation

Validations can get run anywhere in your code. Suggested for it to run early on during boot process

```ruby
# Run configuration validations
unless GemEnforcer::Setup.validate_yml!
  # There are errors in the configuration
  puts GemEnforcer::Setup.errors
end

# Run the validations based on the config file
# If validate_yml! failed, this will raise an error!
GemEnforcer::Setup.run_validations!
```

## Development

This Gem is very close to 100% test coverage. To understand the inner workings, I would start with the test cases

You can run this gem using docker with make commands (`make bash`) or just on your local machine running at least Ruby 3.2.


## Contributing

This gem welcomes contribution.

Bug reports and pull requests are welcome on GitHub at
https://github.com/matt-taylor/gem_enforcer.


