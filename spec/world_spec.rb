# We can't use require because the script doesn't end in .rb.
load File.expand_path("../../selecta", __FILE__)

describe World do
  let("world") { World.blank(["one", "two", "three"]) }

  it "selects the first choice by default" do
    world.selected_choice.should == "one"
  end

  xit "moves down the list" do
    world.down.selected_choice.should == "two"
  end
end
