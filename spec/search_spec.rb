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

  it "handles not matching" do
    lambda { search.append_search_string("a").selected_choice }
      .should raise_error(SystemExit)
  end

  describe "appending" do
    it "allows new choices to be appended" do
      new_search = search.append_new_choices(["four", "five"])
      new_search.choices.size.should == 5
    end

    # This behavior has unfortunate performance implications due to Ruby's
    # mutation-oriented standard library, but this invariant needs to be
    # preserved nonetheless.
    it "doesn't mutate the search object" do
      new_search = search.append_new_choices(["four", "five"])
      search.choices.size.should == 3
    end

    it "silences invalid UTF characters in incoming choices" do
      path = File.expand_path(File.join(File.dirname(__FILE__),
                                        "invalid_utf8.txt"))
      invalid_string = File.read(path)

      new_search = search.append_new_choices([invalid_string])

      new_search.choices[-1].should == ""
      new_search.choices[-1].should_not == invalid_string
    end
  end
end
