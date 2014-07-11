require_relative "spec_helper"

describe Search do
  let(:config) { Configuration.from_inputs(["one", "two", "three"],
                                           Configuration.default_options) }
  let(:search) { Search.blank(config) }

  describe "the selected choice" do
    it "selects the first choice by default" do
      search.selection.should == "one"
    end

    describe "moving down the list" do
      it "moves down the list" do
        search.down.selection.should == "two"
      end

      it "loops around when reaching the end of the list" do
        search.down.down.down.down.selection.should == "two"
      end
      
      it "loops around when reaching the top of the list" do
        search.up.up.selection.should == "two"
      end

      it "loops around when reaching the visible choice limit" do
        config = Configuration.new(2, "", ["one", "two", "three"])
        search = Search.blank(config)
        search.down.down.down.selection.should == "two"
      end

      it "moves down the filtered search results" do
        search.append_search_string("t").down.selection.should == "three"
      end
    end

    it "move up the list" do
      search.down.up.selection.should == "one"
    end

    context "when nothing matches" do
      it "handles not matching" do
        selection = search.append_search_string("doesnt-mtch").selection
        selection.should == Search::NoSelection
      end
    end
  end

  describe "backspacing" do
    let(:search) { Search.blank(config).append_search_string("e") }

    it "backspaces over characters" do
      search.query.should == "e"
      search.backspace.query.should == ""
    end

    it "resets the index" do
      search.backspace.index.should == 0
    end
  end

  it "deletes words" do
    search.append_search_string("").delete_word.query.should == ""
    search.append_search_string("a").delete_word.query.should == ""
    search.append_search_string("a ").delete_word.query.should == ""
    search.append_search_string("a b").delete_word.query.should == "a "
    search.append_search_string("a b ").delete_word.query.should == "a "
    search.append_search_string(" a b").delete_word.query.should == " a "
  end

  it "clears query" do
    search.append_search_string("").clear_query.query.should == ""
    search.append_search_string("a").clear_query.query.should == ""
    search.append_search_string("a ").clear_query.query.should == ""
    search.append_search_string("a b").clear_query.query.should == ""
    search.append_search_string("a b ").clear_query.query.should == ""
    search.append_search_string(" a b").clear_query.query.should == ""
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
end
