describe Search do
  let(:config) { Configuration.from_inputs(["one", "two", "three"],
                                           Configuration.default_options) }
  let(:search) { Search.from_config(config) }

  describe "the selected choice" do
    it "selects the first choice by default" do
      expect(search.selection).to eq "one"
    end

    describe "moving down the list" do
      it "moves down the list" do
        expect(search.down.selection).to eq "two"
      end

      it "loops around when reaching the end of the list" do
        expect(search.down.down.down.down.selection).to eq "two"
      end

      it "loops around when reaching the top of the list" do
        expect(search.up.up.selection).to eq "two"
      end

      it "loops around when reaching the visible choice limit" do
        # The UI height here is 3, but the prompt line subtracts 1, so only two
        # choices are shown.
        config = Configuration.new(3, "", ["one", "two", "three"])
        search = Search.from_config(config)
        expect(search.down.down.down.selection).to eq "two"
      end

      describe "filtered search results" do
        it "moves up and down the list" do
          search = self.search.append_search_string("t")
          expect(search.down.selection).to eq "three"
          expect(search.up.selection).to eq "three"
        end

        it "loops around when reaching the end" do
          search = self.search.append_search_string("t")
          expect(search.down.down.selection).to eq "two"
          expect(search.up.selection).to eq "three"
        end
      end

      describe "everything filtered out" do
        it "can't move up or down" do
          search = self.search.append_search_string("zzz")
          expect(search.down.selection).to eq Search::NoSelection
          expect(search.up.selection).to eq Search::NoSelection
        end
      end
    end

    describe "initial search string" do
      let(:config) { Configuration.new(2, "thr", ["one", "two", "three"]) }
      let(:search) { Search.from_config(config) }

      it "is remembered" do
        expect(search.query).to eq "thr"
      end

      it "filters the results" do
        expect(search.all_matches.map(&:choice)).to eq ["three"]
      end
    end

    it "move up the list" do
      expect(search.down.up.selection).to eq "one"
    end

    context "when nothing matches" do
      it "handles not matching" do
        selection = search.append_search_string("doesnt-mtch").selection
        expect(selection).to be Search::NoSelection
      end
    end
  end

  describe "backspacing" do
    let(:search) { Search.from_config(config).append_search_string("e") }

    it "backspaces over characters" do
      expect(search.query).to eq "e"
      expect(search.backspace.query).to eq ""
    end

    it "resets the index" do
      expect(search.backspace.index).to eq 0
    end
  end

  it "deletes words" do
    expect(search.append_search_string("").delete_word.query).to eq ""
    expect(search.append_search_string("a").delete_word.query).to eq ""
    expect(search.append_search_string("a ").delete_word.query).to eq ""
    expect(search.append_search_string("a b").delete_word.query).to eq "a "
    expect(search.append_search_string("a b ").delete_word.query).to eq "a "
    expect(search.append_search_string(" a b").delete_word.query).to eq " a "
  end

  it "clears query" do
    expect(search.append_search_string("").clear_query.query).to eq ""
    expect(search.append_search_string("a").clear_query.query).to eq ""
    expect(search.append_search_string("a ").clear_query.query).to eq ""
    expect(search.append_search_string("a b").clear_query.query).to eq ""
    expect(search.append_search_string("a b ").clear_query.query).to eq ""
    expect(search.append_search_string(" a b").clear_query.query).to eq ""
  end

  describe "matching" do
    it "only returns matching choices" do
      config = Configuration.from_inputs(["a", "b"],
                                         Configuration.default_options)
      search = Search.from_config(config)
      expect(search.append_search_string("a").best_matches.map(&:choice)).to eq ["a"]
    end

    it "sorts the choices by score" do
      config = Configuration.from_inputs(["spec/search_spec.rb", "search.rb"],
                                         Configuration.default_options)
      search = Search.from_config(config)
      expect(search.append_search_string("search").best_matches.map(&:choice)).to eq [
        "search.rb",
        "spec/search_spec.rb"
      ]
    end
  end

  it "knows when it's done" do
    expect(search.done?).to eq false
    expect(search.done.done?).to eq true
  end
end
