require_relative "spec_helper"

describe Configuration do
  describe "choices" do
    it "removes leading and trailing whitespace" do
      config = Configuration.from_inputs([" a choice "])
      config.choices.should == ["a choice"]
    end

    it "silences invalid UTF characters"
  end
end
