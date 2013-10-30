require_relative "spec_helper"

describe Search do
  let(:config) { Configuration.from_inputs(["one", "two", "three"],
                                           Configuration.default_options) }
  let(:search) { Search.blank(config) }

  it "selects the first choice by default" do
    search.selected_choice.should == "one"
  end

  describe "moving down the list" do
    it "moves down the list" do
      search.down.selected_choice.should == "two"
    end

    it "won't move past the end of the list" do
      search.down.down.down.down.selected_choice.should == "three"
    end

    it "won't move past the visible choice limit" do
      config = Configuration.new(2, "", ["one", "two", "three"])
      search = Search.blank(config)
      search.down.down.down.selected_choice.should == "two"
    end

    it "moves down the filtered search results" do
      search.append_search_string("t").down.selected_choice.should == "three"
    end
  end

  it "move up the list" do
    search.down.up.selected_choice.should == "one"
  end

  it "backspaces over characters" do
    search = self.search.append_search_string("e")
    search.query.should == "e"
    search = search.backspace
    search.query.should == ""
  end

  it "deletes words" do
    search.append_search_string("").delete_word.query.should == ""
    search.append_search_string("a").delete_word.query.should == ""
    search.append_search_string("a ").delete_word.query.should == ""
    search.append_search_string("a b").delete_word.query.should == "a "
    search.append_search_string("a b ").delete_word.query.should == "a "
    search.append_search_string(" a b").delete_word.query.should == " a "
  end

  describe "matching" do
    it "only returns matching choices" do
      config = Configuration.from_inputs(["a", "b"],
                                         Configuration.default_options)
      search = Search.blank(config)
      search.append_search_string("a").matches.should == ["a"]
    end

    it "sorts the choices by score" do
      config = Configuration.from_inputs(["spec/search_spec.rb", "search.rb"],
                                         Configuration.default_options)
      search = Search.blank(config)
      search.append_search_string("search").matches.should == ["search.rb",
                                                               "spec/search_spec.rb"]
    end
  end

  it "knows when it's done" do
    search.done?.should == false
    search.done.done?.should == true
  end

  it "handles not matching" do
    lambda { search.append_search_string("a").selected_choice }
      .should raise_error(SystemExit)
  end
end
