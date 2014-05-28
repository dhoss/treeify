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
    it "should return a scoping" do
      assert_equal AR_SCOPE.name, @node.ancestors.scoped({}).class.name
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

    describe "when specifying :raw" do
      it "should provide a scope" do
        assert_equal AR_SCOPE.name, @root.descendants(:raw).class.name
      end
      it "should not provide root nodes" do
        assert_equal 0, @root.descendants(:raw).count(:conditions => {:parent_id => nil})
      end
      it "should provide all descendants" do
        assert_equal 50, @root.descendants(:raw).count
      end
      it "should allow scope chaining" do
        if(AREL)
          assert @root.descendants(:raw).order(:id).first
        else
          assert @root.descendants(:raw).find(:first, :order => :id)
        end
      end
      it "should allow filtering by depth from current node" do
        if(AREL)
          assert @root.children.include?(@root.descendants(:raw).where(:depth => 0).first), 'Expecting depth filtered descendants to be within Node\'s children'
          assert @root.children.map(&:children).flatten.include?(@root.descendants(:raw).where(:depth => 1).first), 'Expecting depth filtered descendants to be within children of Node\'s children'
        else
          assert @root.children.include?(@root.descendants(:raw).find(:first, :conditions => {:depth => 0})), 'Expecting depth filtered descendants to be within Node\'s children'
          assert @root.children.map(&:children).flatten.include?(@root.descendants(:raw).find(:first, :conditions => {:depth => 1})), 'Expecting depth filtered descendants to be within children of Node\'s children'
        end
      end
    end
  end

  describe "when using an acts_as_sane_tree instance" do
    before do
      @root = Node.roots.first
    end
    it "should know if it is a root node" do
      assert Node.roots.first.root?, 'Expecting root node to affirm root?'
      refute (AREL ? Node.where('parent_id IS NOT NULL').first : Node.find(:first, :conditions => 'parent_id IS NOT NULL')).root?
    end
    it "should provide siblings and not include itself" do
      refute @root.siblings.include?(@root), 'Expecting siblings to not include self'
      refute @root.siblings.detect{|n| !n.parent_id.nil? }, 'Expecting all siblings to be root nodes'
      child = @root.children.first
      assert child, 'Expecting a child node'
      refute child.siblings.include?(child), 'Expecting siblings to not include self'
      refute child.siblings.detect{|n| n.parent_id != child.parent_id}, 'Expecting siblings to have same parent as child'
    end
    it "should provide correct depth" do
      assert_equal 0, @root.depth, 'Expecting depth of root node to be zero'
      assert_equal 1, @root.children.first.depth, 'Expecting depth of child node to be one'
      assert_equal 2, @root.children.first.children.first.depth, 'Expecting depth of child node of child to be two'
    end
  end

  describe "when using an acts_as_sane_tree class" do
    it "should provide all roots" do
      assert_equal Node.count(:conditions => {:parent_id => nil}), Node.roots.count
    end
    it "should provide a single root" do
      assert_kind_of Node, Node.root
      assert Node.root.parent_id.nil?, 'Expecting root node to have no parent'
    end
    describe "when checking for nodes within other node descendants" do
      before do
        @root = Node.root
      end
      it "should return true when source nodes exist within check nodes and descendants" do
        assert Node.nodes_within?(@root.id, @root.children.first.id), 'Expecting child Node to be found within root Node descendant tree'
      end
      it "should return false when source nodes do not exist within check nodes and descendants" do
        refute Node.nodes_within?(@root.id, @root.siblings.first.children.first.id)
      end
      it "should return matching nodes within check nodes and descendants" do
        assert_equal @root.children, Node.nodes_within(@root.id, @root.children)
      end
    end
    describe "when requesting descendants" do
      it "should provide an OrderedHash" do
        assert_kind_of ActiveSupport::OrderedHash, Node.nodes_and_descendants
      end
      it "should provide a scope" do
        assert_equal AR_SCOPE.name, Node.nodes_and_descendants(:raw).class.name
      end
      it "should allow requesting only nodes from a specific depth" do
        Node.nodes_and_descendants(:raw, :at_depth => 0).each do |node|
          assert node.root?, 'Expecting node at zero depth to be root'
        end
        Node.nodes_and_descendants(:raw, :at_depth => 1).each do |node|
          assert_equal 1, node.ancestors.size
        end
        Node.nodes_and_descendants(:raw, :at_depth => 2).each do |node|
          assert_equal 2, node.ancestors.size
        end
      end
      it "should allow requests only node up to a specific depth" do
        Node.nodes_and_descendants(:raw, :to_depth => 0).each do |node|
          assert node.root?, 'Expecting all results to be root nodes'
        end
        Node.nodes_and_descendants(:raw, :to_depth => 1).each do |node|
          assert node.ancestors.size <= 1, 'Expecting nodes to have no more than one ancestors'
        end
        Node.nodes_and_descendants(:raw, :to_depth => 2).each do |node|
          assert node.ancestors.size <= 2, 'Expecting node to have noe more than two ancestors'
        end
      end
    end
  end

