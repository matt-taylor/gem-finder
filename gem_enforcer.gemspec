# frozen_string_literal: true

require_relative "lib/gem_enforcer/version"

Gem::Specification.new do |spec|
  spec.name    = "gem_enforcer"
  spec.version = GemEnforcer::VERSION
  spec.authors = ["Matt Taylor"]
  spec.email   = ["mattius.taylor@gmail.com"]

  spec.summary     = "Long form of the description"
  spec.description = "Provide the ability to validate targetted gems are up to date before executing commands"
  spec.homepage    = "https://github.com/matt-taylor/gem_enforcer"
  spec.license     = "MIT"

  spec.required_ruby_version = Gem::Requirement.new(">= 3.2")

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "class_composer", ">= 1.0"
  spec.add_dependency "faraday"
  spec.add_dependency "octokit"

  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
