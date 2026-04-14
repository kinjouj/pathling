# frozen_string_literal: true

class Pathling
  def initialize(path = "")
    @base  = path
    @parts = []
    @ext   = nil
  end

  def path(*paths)
    @parts = paths.map {|p| p.delete_prefix("/") }
    self
  end

  def with_ext(ext)
    @ext = ext.delete_prefix(".")
    self
  end

  def build
    parts = [@base.delete_suffix("/"), *@parts]

    if @ext
      last      = parts.last
      dot_idx   = last.rindex(".")
      parts[-1] = dot_idx ? "#{last[0...dot_idx]}.#{@ext}" : "#{last}.#{@ext}"
    end

    parts.join("/").freeze
  end

  def to_s
    build
  end

  def self.wrap(path)
    return path if path.is_a?(self)

    new(path)
  end
end
