require 'spec_helper'

describe SimpleTree do
  describe "Initialization" do
    it "is set up correctly" do
      expect(Node.table_name).to eq(:nodes)
      expect(Node.cols).to eq([:name])
    end

    it "has the correct data in the database" do
      pending "fart"
    end
  end

  describe "Roots" do
    it "has a set of root nodes" do
      pending "fart"
    end
  end

  describe "Down the tree" do
    it "retrieves its descendents" do
      pending "fart"
    end
  end

  describe "Back up the tree" do
    it "retrieves its ancestors" do
      pending "fart"
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

