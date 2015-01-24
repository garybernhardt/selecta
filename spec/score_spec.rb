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
      expect(score("xayazxayz", "xyz")).to eq 4
    end

    it "scores the tighter of two matches, regardless of order" do
      tight = "12"
      loose = "1padding2"
      expect(score(tight + loose, "12")).to eq "12".length
      expect(score(loose + tight, "12")).to eq "12".length
    end
  end

  describe "at word boundaries" do
    it "doesn't score characters before a match at a word boundary" do
      expect(score("fooxbar", "foobar")).to eq 7
      expect(score("foo-x-bar", "foobar")).to eq 6
      expect(score("./spec/score_spec.rb", "specscorespecrb"))
      .to eq "specscorespecrb".length
      #expect(score("./spec/score_spec.rb", "scorerb"))
      #.to eq "scorerb".length
    end

    it "finds optimal non-boundary matches when boundary matches are present" do
      # The "xay" matches in both cases because it's shorter than "xaa-aay"
      # even considering the latter's boundary bonus.
      expect(score("xayz/x-yaaz", "xyz")).to eq 4
      expect(score("x-yaaz/xayz", "xyz")).to eq 4
    end

    it "finds optimal boundary matches when non-boundary matches are present" do
      expect(score("x-yaz/xaaaayz", "xyz")).to eq 4
      expect(score("xaaaayz/x-yaz", "xyz")).to eq 4
    end
  end

  describe "complex matching situations" do
    xit "favors initials at the beginning of the match" do
      with_initial = score("app/model/user", "amu")
      without_initial = score("theapp/model/user", "amu")
      expect(with_initial).to eq (without_initial - 1)
    end

    xit "favors sequential characters to boundary matches" do
      sequential = score("lib/selecta.rb", "electa")
      non_sequential = score("lib/selector/average.rb", "electa")
      expect(sequential).to eq (non_sequential - 1)
    end

    it "sometimes doesn't find the best match; the algorithm isn't fully general" do
      # With an optimal algorithm, this would score 3. It would find the
      # initial "x", then the "yz" at the end.
      expect(score("x/yaaaz/yz", "xyz")).to eq 6
    end
  end
end
