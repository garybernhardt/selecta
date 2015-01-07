require_relative "spec_helper"

describe "score" do
  def score(choice, query)
    Score.score(choice, query)
  end

  describe "basic matching" do
    it "isn't a match when the choice is empty" do
      expect(score("", "a")).to eq NonMatch
    end

    it "isn't a match when the query is longer than the choice" do
      expect(score("short", "longer")).to eq NonMatch
    end

    it "isn't a match when the query doesn't match at all" do
      expect(score("a", "b")).to eq NonMatch
    end

    it "isn't a match when only a prefix of the query matches" do
      expect(score("ab", "ac")).to eq NonMatch
    end

    it "has a score when it matches" do
      expect(score("a", "a").score).to be > 0
      expect(score("ab", "a").score).to be > 0
      expect(score("ba", "a").score).to be > 0
      expect(score("bab", "a").score).to be > 0
      expect(score("babababab", "aaaa").score).to be > 0
    end

    it "scores the length of the match" do
      expect(score("a", "a").score).to eq 1.0
      expect(score("ab", "ab").score).to eq 2
      expect(score("a long string", "a long string").score).to eq "a long string".length
      expect(score("spec/search_spec.rb", "sear").score).to eq "sear".length
    end
  end

  describe "character matching" do
    it "matches punctuation" do
      expect(score("/! symbols $^", "/!$^").score).to be > 0.0
    end

    it "is case insensitive" do
      expect(score("a", "A").score).to eq 1.0
      expect(score("A", "a").score).to eq 1.0
    end

    it "doesn't match when the same letter is repeated in the choice" do
      expect(score("a", "aa")).to eq NonMatch
    end
  end

  describe "match quality" do
    it "scores lower (better) for better matches" do
      expect(score("selecta.gemspec", "asp").score).to be < score("algorithm4_spec.rb", "asp").score
      expect(score("README.md", "em").score).to be < score("benchmark.rb", "em").score
    end

    it "scores shorter matches higher" do
      expect(score("fbb", "fbb").score).to be < score("foo bar baz", "fbb").score
      expect(score("1x2x3x4", "1x2x3").score).to be < score("1x9x2x3x4", "1x2x3").score
    end

    it "sometimes scores longer strings higher if they have a better match" do
      expect(score("long 12 long", "12").score).to be < score("1 long 2", "12").score
    end

    it "scores the tighter of two matches, regardless of order" do
      tight = "12"
      loose = "1padding2"
      expect(score(tight + loose, "12").score).to eq "12".length
      expect(score(loose + tight, "12").score).to eq "12".length
    end
  end
end
