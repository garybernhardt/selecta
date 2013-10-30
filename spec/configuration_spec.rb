require "base64"
require_relative "spec_helper"

describe Configuration do
  describe "choices" do
    it "removes leading and trailing whitespace" do
      config = Configuration.from_inputs([" a choice "],
                                         Configuration.default_options)
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
      config = Configuration.from_inputs([invalid_string],
                                         Configuration.default_options)
      config.choices.should == [""]
      config.choices.should_not == [invalid_string]
    end
  end

  describe "command line options" do
    describe "search queries" do
      it "can be specified" do
        config = Configuration.from_inputs(
          [], Configuration.parse_options(["-s", "some search"]))
        config.initial_search.should == "some search"
      end

      it "defaults to the empty string" do
        config = Configuration.from_inputs([], Configuration.default_options)
        config.initial_search.should == ""
      end
    end
  end
end
