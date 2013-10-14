require "base64"
require_relative "spec_helper"

describe Configuration do
  describe "choices" do
    it "removes leading and trailing whitespace" do
      config = Configuration.from_inputs([" a choice "])
      config.choices.should == ["a choice"]
    end

    it "silences invalid UTF characters" do
      path = File.expand_path(File.join(File.dirname(__FILE__),
                                        "invalid_utf8.txt"))
      invalid_string = File.read(path)

      # Make sure that the string is actually invalid.
      expect do
        invalid_string.strip
      end.to raise_error(ArgumentError, /invalid byte sequence in UTF-8/)

      # We should silently fix the error
      expect do
        Configuration.from_inputs([invalid_string])
      end.not_to raise_error
    end
  end
end
