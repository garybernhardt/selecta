require_relative "spec_helper"

describe "score" do
  def score(choice, query)
    score, range = Score.score(choice, query)
    if range
      score
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

    it "has a perfect score for a single letter at a word boundary" do
      expect(score("a", "a")).to eq 1
      expect(score("ab", "a")).to eq 1
      expect(score("foo/a", "a")).to eq 1
    end

    it "has an imperfect score when not starting on a word boundary" do
      expect(score("ba", "a")).to be > 0
      expect(score("bab", "a")).to be > 0
      expect(score("babababab", "aaaa")).to be > 0
    end

    it "for exact sequential matches, each character after the first is free" do
      expect(score("ax", "x")).to eq 2
      expect(score("axya", "xy")).to eq 2
      expect(score("axyza", "xyz")).to eq 2
    end
  end

  describe "character matching" do
    it "matches punctuation" do
      expect(score("/! symbols $^", "/!$^")).to be > 0.0
    end

    it "is case sensitive, because case insensitivity is provided elsewhere" do
      expect(score("a", "A")).to eq nil
      expect(score("A", "a")).to eq nil
    end

    it "doesn't match when the same letter is repeated in the choice" do
      expect(score("a", "aa")).to eq nil
    end
  end

  describe "match quality" do
    it "scores lower (better) for better matches" do
      expect(score("selecta.gemspec", "asp")).to be < score("algorithm4spec.rb", "asp")
      expect(score("readme.md", "em")).to be < score("benchmark.rb", "em")
    end

    it "scores shorter matches higher" do
      expect(score("fbb", "fbb")).to be < score("foobarbaz", "fbb")
      expect(score("1x2x3x4", "1x2x3")).to be < score("1x9x2x3x4", "1x2x3")
    end

    it "scores longer strings better than short ones if they match better" do
      expect(score("long12long", "12")).to be < score("1long2", "12")
    end

    it "finds good matches, even if they appear after worse matches" do
      expect(score("axayazaxayz", "xyz")).to eq score("axayz", "xyz")
    end

    it "scores the tighter of two matches, regardless of order" do
      tight = "a12"
      loose = "a1padding2"
      expect(score(tight + loose, "12")).to eq score(tight, "12")
      expect(score(loose + tight, "12")).to eq score(tight, "12")
    end
  end

  describe "at word boundaries" do
    it "doesn't score characters before a match at a word boundary" do
      expect(score("axa-y", "xy")).to be < score("axay", "xy")
    end

    it "finds optimal boundary matches when non-boundary matches are present" do
      score1 = score("ax-yaz/axaaaayz", "xyz")
      score2 = score("axaaaayz/ax-yaz", "xyz")
      expect(score1).to eq score2
    end
  end

  describe "complex matching situations" do
    it "favors initials over sequential matches" do
      with_initial = score("./app/model/user", "amu")
      without_initial = score("./ast/multiline_argument.rb", "amu")
      expect(with_initial).to be < (without_initial - 1)
    end

    describe "sequential characters vs. word boundaries" do
      it "scores word boundaries equal to long sequential matches when starting mid-word" do
        sequential = score("lib/selecta.rb", "electa")
        with_word_boundary = score("lib/selector/average.rb", "electa")
        expect(sequential).to be < with_word_boundary
      end

      it "scores long sequential equal to word boundaries when starting on a boundary" do
        sequential = score("lib/selecta.rb", "selecta")
        with_word_boundary = score("selector/abstract_sequence", "selecta")
        expect(sequential).to be < with_word_boundary
      end
    end

    it "sometimes doesn't find the best match; the algorithm isn't fully general" do
      # With an optimal algorithm, this would find the initial "x", then the
      # final "yz" at word boundary. Our algorithm isn't optimal, so we get the
      # "yaaaz" instead of the "yz".
      expect(score("ax/yaaaz/yz", "xyz")).to eq score("ax/yaaaz", "xyz")
    end
  end
end
