# frozen_string_literal: true

require "pathling"

describe Pathling do
  let(:base_path) { "https://api.example.com" }
  let(:uri) { described_class.new(base_path) }

  describe "#initialize" do
    it "assigns the base path" do
      expect(uri.base).to eq base_path
    end

    it "initializes with empty parts and nil extension" do
      expect(uri.parts).to be_empty
      expect(uri.extension).to be_nil
    end
  end

  describe "#path" do
    it "returns a new instance and does not mutate the original" do
      new_uri = uri.path("v1", "users")
      expect(new_uri).not_to eq uri
      expect(uri.parts).to be_empty
    end

    it "removes leading slashes from parts" do
      new_uri = uri.path("/v1", "/users/")
      expect(new_uri.parts).to eq ["v1", "users/"]
    end
  end

  describe "#with_ext" do
    it "returns a new instance with the specified extension" do
      new_uri = uri.with_ext(".json")
      expect(new_uri.extension).to eq "json"
    end

    it "handles extension string without a leading dot" do
      new_uri = uri.with_ext("csv")
      expect(new_uri.extension).to eq "csv"
    end
  end

  describe "#build" do
    it "joins parts into a valid path" do
      result = uri.path("v1", "items").build
      expect(result).to eq "https://api.example.com/v1/items"
    end

    it "appends the extension to the path" do
      result = uri.path("image").with_ext("png").build
      expect(result).to eq "https://api.example.com/image.png"
    end

    it "replaces an existing extension" do
      result = described_class.new("file.txt").with_ext("pdf").build
      expect(result).to eq "file.pdf"
    end

    it "appends an extension to a directory-like path" do
      result = described_class.new("dir/").with_ext("zip").build
      expect(result).to eq "dir.zip"
    end

    it "only replaces the last extension in complex paths" do
      result = described_class.new("my.dir/file.tar.gz").with_ext("zip").build
      expect(result).to eq "my.dir/file.tar.zip"
    end
  end

  describe ".wrap" do
    it "returns the same instance if already a Simpress::Uri" do
      expect(described_class.wrap(uri)).to eq uri
    end

    it "creates a new instance if a string is given" do
      wrapped = described_class.wrap("test")
      expect(wrapped).to be_a(described_class)
      expect(wrapped.base).to eq "test"
    end
  end

  describe "delegation" do
    it "delegates to_s to the build method" do
      expect(uri.path("test").to_s).to eq uri.path("test").build
    end
  end
end
