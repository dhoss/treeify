require 'spec_helper'

describe Treeify do
  describe "Initialization" do
    it "has the correct config values" do
      expect(Node.cols).to eq([:name])
    end

    it "is set up correctly" do
      expect(Node.table_name).to eq("nodes")
    end

    it "has the correct data in the database" do
      expect(Node.roots.count).to eq(3)
      expect(Node.roots.first.descendents.count).to eq(50)
    end

    it "retrieves all the columns defined in the configuration" do
      expected_sql = "WITH RECURSIVE cte (id, parent_id, path, name)  AS (
         SELECT  id,
           parent_id,
           array[id] AS path, name
         FROM    nodes
         WHERE   id = 1

         UNION ALL

         SELECT  nodes.id,
            nodes.parent_id,
            cte.path || nodes.id, nodes.name
         FROM    nodes
         JOIN cte ON nodes.parent_id = cte.id
       )"
      expect(Node.tree_sql(Node.first)).to eq(expected_sql)
    end
  end

  describe "Utility methods" do
    it "joins the columns with a characer" do
      pending "Still trying to get this working"
      Treeify.cols << :another_test_column
      expect(Treeify.columns_joined(",")).to eq("another_test_column,name")
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

    it "adds children to child nodes" do
      root = Node.roots.first
      child = root.children.create(name: "new child node")
      subchild = child.children.create(name: "new subchild node")
      expect(child.children.count).to eq(1)
    end

    it "has the correct tree after subchildren are added" do
      pending "This is a bug"
      tree = Node.roots.first.self_and_descendents
      tree.each do |node|
        if node.parent_id.nil?
          expect(node.ancestors.count).to eq(0)
        end
      end
    end

    it "deletes subchildren"

    it "re-parents children"

    it "has the correct tree after children are re-parented"

    it "retrieves siblings" do
      10.times do |n|
        Node.create(name: "sib_#{n}", parent_id: Node.roots.first.id)
      end
      sib = Node.where(name: "sib_1").take
      expect(sib.siblings.count).to eq(12)
    end

    it "adds siblings"

    it "updates siblings"

    it "deletes siblings"

    it "builds the descendents_tree properly" do
      parent = Node.create(name: "tree root")
      parent.children << Node.new(name: "child 1")
      parent.children.first.children << Node.new(name: "child 2")
      child = parent.children.first
      subchild = child.children.first
      expect(parent.descendent_tree).to match_array([
        {
          "id"        => child.id,
          "parent_id" => parent.id,
          "path"      => [parent.id, child.id], 
          "name"      => child.name,
          "children" => [
            {
              "id"        => subchild.id,
              "parent_id" => child.id,
              "path"      => [parent.id, child.id, subchild.id],
              "name"      => subchild.name,
              "children"  => []
            }
          ]
       }
      ])
    end
  end
end

