# frozen_string_literal: true

require "pathling"

describe Pathling do
  describe "#initialize" do
    it "accepts no arguments" do
      expect { described_class.new }.not_to raise_error
    end

    it "accepts an empty string" do
      expect { described_class.new("") }.not_to raise_error
    end

    it "accepts a non-empty string as base" do
      expect { described_class.new("https://example.com") }.not_to raise_error
    end
  end

  describe "#path" do
    it "sets a single path segment" do
      uri = described_class.new("base").path("foo")
      expect(uri.build).to eq("base/foo")
    end

    it "sets multiple path segments" do
      uri = described_class.new("base").path("foo", "bar", "baz")
      expect(uri.build).to eq("base/foo/bar/baz")
    end

    it "strips leading slashes from each segment" do
      uri = described_class.new("base").path("/foo", "/bar")
      expect(uri.build).to eq("base/foo/bar")
    end

    it "does not strip internal slashes" do
      uri = described_class.new("base").path("foo/bar")
      expect(uri.build).to eq("base/foo/bar")
    end

    it "replaces previously set path segments on second call" do
      uri = described_class.new("base").path("first", "second").path("third")
      expect(uri.build).to eq("base/third")
    end

    it "resets path segments when called with no arguments" do
      uri = described_class.new("base").path("foo").path
      expect(uri.build).to eq("base")
    end

    it "returns self for method chaining" do
      uri = described_class.new("base")
      expect(uri.path("foo")).to be(uri)
    end
  end

  describe "#with_ext" do
    it "replaces an existing extension on the last segment" do
      uri = described_class.new("base").path("file.md").with_ext("html")
      expect(uri.build).to eq("base/file.html")
    end

    it "adds an extension when the last segment has none" do
      uri = described_class.new("base").path("file").with_ext("html")
      expect(uri.build).to eq("base/file.html")
    end

    it "replaces only the last extension when the segment has multiple dots" do
      uri = described_class.new("base").path("file.test.md").with_ext("html")
      expect(uri.build).to eq("base/file.test.html")
    end

    it "strips a leading dot from the extension argument" do
      uri = described_class.new("base").path("file.md").with_ext(".html")
      expect(uri.build).to eq("base/file.html")
    end

    it "applies to the last segment among multiple path segments" do
      uri = described_class.new("base").path("a", "b", "file.md").with_ext("html")
      expect(uri.build).to eq("base/a/b/file.html")
    end

    it "returns self for method chaining" do
      uri = described_class.new("base")
      expect(uri.with_ext("html")).to be(uri)
    end
  end

  describe "#build" do
    it "returns the base alone when no path segments are set" do
      uri = described_class.new("https://example.com")
      expect(uri.build).to eq("https://example.com")
    end

    it "joins base and path segments with forward slashes" do
      uri = described_class.new("https://example.com").path("a", "b")
      expect(uri.build).to eq("https://example.com/a/b")
    end

    it "strips a trailing slash from the base before joining" do
      uri = described_class.new("https://example.com/").path("a", "b")
      expect(uri.build).to eq("https://example.com/a/b")
    end

    it "produces a leading slash when the default empty base is used" do
      uri = described_class.new.path("foo", "bar")
      expect(uri.build).to eq("/foo/bar")
    end

    it "returns an empty string when base is empty and no path is set" do
      uri = described_class.new("")
      expect(uri.build).to eq("")
    end

    it "returns a frozen string" do
      uri = described_class.new("base").path("foo")
      expect(uri.build).to be_frozen
    end

    it "does not mutate internal state across calls" do
      uri = described_class.new("base").path("file.md").with_ext("html")
      uri.build
      expect(uri.build).to eq("base/file.html")
    end
  end

  describe "#to_s" do
    it "returns the same value as build" do
      uri = described_class.new("base").path("foo", "bar").with_ext("html")
      expect(uri.to_s).to eq(uri.build)
    end

    it "returns a frozen string" do
      expect(described_class.new("base").to_s).to be_frozen
    end
  end

  describe ".wrap" do
    it "returns the exact same instance when given a Uri" do
      uri = described_class.new("base")
      expect(described_class.wrap(uri)).to be(uri)
    end

    it "wraps a plain String in a new Uri instance" do
      wrapped = described_class.wrap("https://example.com")
      expect(wrapped).to be_a(described_class)
    end

    it "preserves the String value when wrapping" do
      wrapped = described_class.wrap("https://example.com")
      expect(wrapped.build).to eq("https://example.com")
    end

    it "does not wrap a subclass instance as a new Uri" do
      subclass = Class.new(described_class)
      instance = subclass.new("base")
      expect(described_class.wrap(instance)).to be(instance)
    end
  end
end
