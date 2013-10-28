require_relative "spec_helper"

describe Search do
  let(:config) { Configuration.from_inputs(["one", "two", "three"],
                                           Configuration.default_options) }
  let(:world) { Search.blank(config) }

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
      config = Configuration.new(2, "", ["one", "two", "three"])
      world = Search.blank(config)
      world.down.down.down.selected_choice.should == "two"
    end

    it "moves down the filtered search results" do
      world.append_search_string("t").down.selected_choice.should == "three"
    end
  end

  it "move up the list" do
    world.down.up.selected_choice.should == "one"
  end

  it "backspaces over characters" do
    world = self.world.append_search_string("e")
    world.query.should == "e"
    world = world.backspace
    world.query.should == ""
  end

  it "deletes words" do
    world.append_search_string("").delete_word.query.should == ""
    world.append_search_string("a").delete_word.query.should == ""
    world.append_search_string("a ").delete_word.query.should == ""
    world.append_search_string("a b").delete_word.query.should == "a "
    world.append_search_string("a b ").delete_word.query.should == "a "
    world.append_search_string(" a b").delete_word.query.should == " a "
  end

  describe "matching" do
    it "only returns matching choices" do
      config = Configuration.from_inputs(["a", "b"],
                                         Configuration.default_options)
      world = Search.blank(config)
      world.append_search_string("a").matches.should == ["a"]
    end

    it "sorts the choices by score" do
      config = Configuration.from_inputs(["spec/search_spec.rb", "search.rb"],
                                         Configuration.default_options)
      world = Search.blank(config)
      world.append_search_string("search").matches.should == ["search.rb",
                                                              "spec/search_spec.rb"]
    end
  end

  it "knows when it's done" do
    world.done?.should == false
    world.done.done?.should == true
  end

  it "handles not matching" do
    lambda { world.append_search_string("a").selected_choice }
      .should raise_error(SystemExit)
  end
end
