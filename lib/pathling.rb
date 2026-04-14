# frozen_string_literal: true

require "forwardable"

class Pathling
  extend Forwardable

  def_delegators :build, :to_s, :inspect
  attr_reader :base, :parts, :extension

  PREFIX_SLASH = %r{^/}
  EXTENSION_PATTERN = %r{(\.[^./]+)?$}

  def initialize(base = "")
    @base = base.to_s.freeze
    @parts = []
    @extension = nil
  end

  def path(*paths)
    dup.tap do |new_uri|
      new_uri.instance_variable_set(:@parts, paths.map {|p| p.to_s.sub(PREFIX_SLASH, "") })
    end
  end

  def with_ext(ext)
    dup.tap do |new_uri|
      new_uri.instance_variable_set(:@extension, ext&.to_s&.delete_prefix("."))
    end
  end

  def build
    all_parts = [base, *parts].reject(&:empty?)
    full_path = all_parts.join("/")
    return full_path unless extension

    apply_extension(full_path)
  end

  def self.wrap(path)
    path.is_a?(self) ? path : new(path)
  end

  private

  def apply_extension(path)
    return path if path.empty?

    if path.end_with?("/")
      "#{path.chop}.#{extension}"
    else
      path.sub(EXTENSION_PATTERN, ".#{extension}")
    end
  end
end
