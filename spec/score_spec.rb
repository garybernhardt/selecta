require_relative "spec_helper"

describe "score" do
  def score(choice, query)
    range = Score.score(choice, query)
    if range
      range.count
    else
      nil
    end
  end

  describe "basic matching" do
    it "isn't a match when the choice is empty" do
      expect(score("", "a")).to eq nil
    end

    it "isn't a match when the query is longer than the choice" do
      expect(score("short", "longer")).to eq nil
    end

    it "isn't a match when the query doesn't match at all" do
      expect(score("a", "b")).to eq nil
    end

    it "isn't a match when only a prefix of the query matches" do
      expect(score("ab", "ac")).to eq nil
    end

    it "has a score when it matches" do
      expect(score("a", "a")).to be > 0
      expect(score("ab", "a")).to be > 0
      expect(score("ba", "a")).to be > 0
      expect(score("bab", "a")).to be > 0
      expect(score("babababab", "aaaa")).to be > 0
    end

    it "scores the length of the match" do
      expect(score("a", "a")).to eq 1.0
      expect(score("ab", "ab")).to eq 2
      expect(score("a long string", "a long string")).to eq "a long string".length
      expect(score("spec/search_spec.rb", "sear")).to eq "sear".length
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
      expect(score("a", "aa")).to eq nil
    end
  end

  describe "match quality" do
    it "scores lower (better) for better matches" do
      expect(score("selecta.gemspec", "asp")).to be < score("algorithm4_spec.rb", "asp")
      expect(score("README.md", "em")).to be < score("benchmark.rb", "em")
    end

    it "scores shorter matches higher" do
      expect(score("fbb", "fbb")).to be < score("foo bar baz", "fbb")
      expect(score("1x2x3x4", "1x2x3")).to be < score("1x9x2x3x4", "1x2x3")
    end

    it "sometimes scores longer strings higher if they have a better match" do
      expect(score("long 12 long", "12")).to be < score("1 long 2", "12")
    end

    it "scores the tighter of two matches, regardless of order" do
      tight = "12"
      loose = "1padding2"
      expect(score(tight + loose, "12")).to eq "12".length
      expect(score(loose + tight, "12")).to eq "12".length
    end
  end
end
