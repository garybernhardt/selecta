# We can't use require because the script doesn't end in .rb.
load File.expand_path("../../selecta", __FILE__)

describe World do
  let(:options) { Options.new(20) }
  let(:world) { World.blank(options, ["one", "two", "three"]) }

  it "selects the first choice by default" do
    world.selected_choice.should == "one"
  end

  describe "moving down the list" do
    it "moves down the list" do
      world.down.selected_choice.should == "two"
    end

    it "won't move past the end of the list" do
      world.down.down.down.down.selected_choice.should == "three"
    end

    it "won't move past the visible choice limit" do
      options = Options.new(2)
      world = World.blank(options, ["one", "two", "three"])
      world.down.down.down.selected_choice.should == "two"
    end

    it "moves down the filtered search results"
  end

  it "move up the list" do
    world.down.up.selected_choice.should == "one"
  end

  it "filters by substring" do
    world.append_search_string("e").matches.should == ["one", "three"]
  end
end
