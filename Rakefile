# frozen_string_literal: true

require "rake/extensiontask"
require "rspec/core/rake_task"

Rake::ExtensionTask.new("pathling") do |ext|
  ext.lib_dir = "lib/pathling"
  ext.ext_dir = "ext/pathling"
end

RSpec::Core::RakeTask.new(:spec)
