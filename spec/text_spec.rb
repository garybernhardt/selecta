describe Text do
  describe "truncates length" do
    let(:text) { Text["this is long"] }

    it "truncates itself to a given width" do
      expect(text.truncate_to_width(6)).to eq(Text["this i"])
    end
  end

  describe "when truncating" do
    let(:text) { Text[:red, "one", :green, "two", :blue, "three"] }

    it "leaves an empty string behind" do
      expect(text.truncate_to_width(2)).to eq(Text[:red, "on", :green, "", :blue, ""])
    end
  end
end
