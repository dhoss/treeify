require 'spec_helper'

describe Treeify do
  describe "Initialization" do
    it "is set up correctly" do
      expect(Node.table_name).to eq("nodes")
      expect(Node.cols).to eq([:name])
    end

    it "has the correct data in the database" do
      expect(Node.roots.count).to eq(3)
      expect(Node.roots.first.descendents.count).to eq(50)
    end
  end

  describe "Down the tree" do
    subject(:parent) { Node.roots.first }
    it "retrieves its descendents" do
      expect(parent.descendents.count).to eq(50)
      # self_and_descendents - [self] == 49
      expect(parent.descendents.first.descendents.count).to eq(49)
    end
  end

  describe "Back up the tree" do
    subject(:descendent) { Node.roots.first.descendents.first }
    it "retrieves its ancestors" do
      expect(descendent.ancestors.count).to eq(49)
    end
  end

  describe "Modifying the tree" do
    it "adds a new child" do
      pending "fart"
    end

    it "updates a child" do
      pending "fart"
    end

    it "deletes a child" do
      pending "fart"
    end
  end
end

