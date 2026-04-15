# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "pathling"
  spec.version = "0.0.1"
  spec.authors = ["kinjouj"]
  spec.email = ["kinjouj@gmail.com"]
  spec.summary = "pathling"
  spec.description = "pathling"
  spec.homepage = "https://github.com/kinjouj/pathling"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"
  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kinjouj/pathling"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.files = Dir["lib/**/*", "ext/**/*", "*.gemspec"]
  spec.extensions = ["ext/pathling/extconf.rb"]
  spec.require_paths = ["lib"]
end
