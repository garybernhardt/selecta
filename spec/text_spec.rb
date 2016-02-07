require_relative "spec_helper"

describe Text do
  describe "truncating" do
    it "can truncate itself to a given width" do
      Text["this is long"].truncate_to_width(6).should == Text["this i"]
    end

    it "sometimes leaves empty strings behind when truncating" do
      text = Text[:red, "one", :green, "two", :blue, "three"]
      text.truncate_to_width(2).should == Text[:red, "on", :green, "", :blue, ""]
    end
  end
end
