require_relative "spec_helper"

describe "score" do
  def score(choice, query)
    Score.score(choice, query)
  end

  describe "basic matching" do
    it "scores 0 when the choice is empty" do
      expect(score("", "a")).to eq 0
    end

    it "scores 1 when the query is empty" do
      expect(score("a", "")).to eq 1
    end

    it "scores 0 when the query is longer than the choice" do
      expect(score("short", "longer")).to eq 0
    end

    it "scores 0 when the query doesn't match at all" do
      expect(score("a", "b")).to eq 0
    end

    it "scores 0 when only a prefix of the query matches" do
      expect(score("ab", "ac")).to eq 0
    end

    it "scores greater than 0 when it matches" do
      expect(score("a", "a")).to be > 0
      expect(score("ab", "a")).to be > 0
      expect(score("ba", "a")).to be > 0
      expect(score("bab", "a")).to be > 0
      expect(score("babababab", "aaaa")).to be > 0
    end

    it "scores 1, normalized to length, when the query equals the choice" do
      expect(score("a", "a")).to eq 1.0
      expect(score("ab", "ab")).to eq 0.5
      expect(score("a long string", "a long string")).to eq 1.0 / "a long string".length
      expect(score("spec/search_spec.rb", "sear")).to eq 1.0 / "spec/search_spec.rb".length
    end
  end

  describe "character matching" do
    it "matches punctuation" do
      expect(score("/! symbols $^", "/!$^")).to be > 0.0
    end

    it "is case insensitive" do
      expect(score("a", "A")).to eq 1.0
      expect(score("A", "a")).to eq 1.0
    end

    it "doesn't match when the same letter is repeated in the choice" do
      expect(score("a", "aa")).to eq 0.0
    end
  end

  describe "match quality" do
    it "scores higher for better matches" do
      expect(score("selecta.gemspec", "asp")).to be > score("algorithm4_spec.rb", "asp")
      expect(score("README.md", "em")).to be > score("benchmark.rb", "em")
      expect(score("search.rb", "sear")).to be > score("spec/search_spec.rb", "sear")
    end

    it "scores shorter matches higher" do
      expect(score("fbb", "fbb")).to be > score("foo bar baz", "fbb")
      expect(score("foo", "foo")).to be > score("longer foo", "foo")
      expect(score("foo", "foo")).to be > score("foo longer", "foo")
      expect(score("1/2/3/4", "1/2/3")).to be > score("1/9/2/3/4", "1/2/3")
    end

    it "sometimes scores longer strings higher if they have a better match" do
      expect(score("long 12 long", "12")).to be > score("1 long 2", "12")
    end

    it "scores the tighter of two matches, regardless of order" do
      tight = "12"
      loose = "1padding2"
      expect(score(tight + loose, "12")).to eq 1.0 / (tight + loose).length
      expect(score(loose + tight, "12")).to eq 1.0 / (loose + tight).length
    end
  end
end
