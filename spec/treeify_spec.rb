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
      root = Node.roots.first
      root.children << Node.create(name: "new child node")
      child = root.children.where(name: "new child node").take
      expect(child.name).to eq("new child node")
    end

    it "has the correct parent" do
      root = Node.roots.first
      child = Node.where(name: "new child node").take
      expect(child.parent.id).to eq(root.id)
    end

    it "updates a child" do
      root = Node.roots.first
      child = Node.where(name: "new child node").take
      child.name = "fart nuggets"
      child.save
      expect(child.name).to eq("fart nuggets")
    end


    it "deletes a child" do
      root = Node.roots.first
      child = Node.where(name: "new child node").take
      Node.delete(child)
      expect(Node.where(name: "new child node").take).to eq(nil)
    end

    it "adds children to child nodes"

    it "has the correct tree after subchildren are added"

    it "deletes subchildren"

    it "re-parents children"

    it "has the correct tree after children are re-parented"

    it "retrieves siblings"

    it "adds siblings"

    it "updates siblings"

    it "deletes siblings"


  end
end

