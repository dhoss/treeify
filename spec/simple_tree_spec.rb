require 'spec_helper'

describe SimpleTree do

  describe "after suite setup" do
    it "should have populated nodes" do
      Node.count.should be  > 0
      Node.count(:conditions => {:parent_id => nil}).should be > 0
      Node.count(:conditions => "#{Node.table_name}.parent_id IS NOT NULL").should be > 0
    end
  end

  describe "when requesting root nodes" do
    it "should return all root nodes" do
      Node.where(parent_id: nil).count.should == Node.roots.count
      Node.roots.map(&:parent_id).detect{|x|!x.nil?.should == true}
    end
    it "should allow scope chaining" do
      expect(Node.where(name:'node_0').first).to eq(Node.roots.where(name: 'node_0').first)
    end
  end
  it "should show root nodes having a depth of 0" do
    Node.roots.map(&:depth).detect{|d| d.should_not be > 0}
  end
end

describe "when requesting parent" do
  it "should be nil for root nodes" do
    Node.roots.first.parent.should be nil # 'Expecting root Node to have no parent'
  end
  it "should provide parent node" do
    node = Node.where('nodes.parent_id IS NOT NULL').take
    node.parent.should_not be nil
    node.parent.should be_a(Node)
    node.parent.children.limit(10).include?(node).should == true
  end
end

describe "when requesting children" do
  it "should provide nodes with parent's ID set to parent.id" do
    parent = Node.roots.first
    parent.children.each do |node|
      expect(parent.id).to eq(node.parent_id)
    end
  end
  it "should allow scope chaining" do
    parent = Node.roots.first
    expect(Node.find(:first, :conditions => {:parent_id => parent.id}, :order => :id)).to
    eq(parent.children.find(:first, :order => :id))
  end
end

describe "when requesting ancestors" do
  before do
    @node = Node.last
  end
  it "should provide ancestor chain in correct order with root being at the zero index" do
    holder = @node
    @node.ancestors.reverse.each do |node|
      assert_equal holder.parent, node
      holder = holder.parent
    end
    assert holder.root?, 'Expecting holder Node to be root'
    assert_equal holder, @node.ancestors.first
  end
  it "should allow scope chaining" do
    if(AREL)
      assert @node.ancestors.order(:id).first
    else
      assert @node.ancestors.find(:first, :order => :id)
    end
  end
end

describe "when requesting descendants" do
  before do
    @root = Node.roots.first
  end
  describe "when not specifying :raw" do
    it "should provide an nested hash of descendants" do
      descendants = @root.descendants
      assert_kind_of ActiveSupport::OrderedHash, descendants
    end
    it "should have root keys that are children of the node" do
      @root.descendants.keys.each do |node|
        assert @root.children.include?(node), 'Expecting root hash keys to be child Node of root'
      end
    end
    it "should provide node keys with hash values or nils" do
      runner = lambda do |hash|
        hash.each_pair do |node, child_hash|
          unless(child_hash.nil?)
            child_hash.keys.each do |child_node|
              assert node.children.include?(child_node), 'Expecting key node to be valid child of parent node'
            end
            runner.call(child_hash)
          else
            pass
          end
        end
      end
      runner.call(@root.descendants)
    end
  end
end

