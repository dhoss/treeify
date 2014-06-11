require 'rubygems'
require 'bundler/setup'
require 'active_record'
require 'active_record/migration'
require 'benchmark'
require 'simple_tree'
require 'rspec/autorun'
require 'database_cleaner'

ActiveRecord::Base.establish_connection(
  :adapter => 'postgresql',
  :database => 'tree_test',
  :username => 'postgres'
)

ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV['SHOW_SQL']

class Node < ActiveRecord::Base
  validates_uniqueness_of :name
  validates_uniqueness_of :parent_id, :scope => :id
  include SimpleTree
  config({ :table_name => :nodes, :columns => [:name]})
end

class NodeSetup < ActiveRecord::Migration
  class << self
    def up
      create_table :nodes do |t|
        t.text :name
        t.integer :parent_id
        t.references :parent
      end
      add_index :nodes, [:parent_id, :id], :unique => true
    end

    def down 
      drop_table :nodes
    end
  end
end

RSpec.configure do |config|

  config.before(:suite) do                                                                                       
    NodeSetup.up
    # Create three root nodes with 50 descendants
    # Descendants should branch randomly

    nodes = []

    3.times do |i|
      nodes[i] = []
      parent = Node.create(:name => "root_#{i}")
      50.times do |j|
        node = Node.new(:name => "node_#{i}_#{j}")
        _parent = nodes[i][rand(nodes[i].size)] || parent
        node.parent_id = _parent.id
        node.save
        nodes[i] << node
      end
    end   
  end                                                                                                            
                                                                                                                 
  config.after(:suite) do                                                                                         
    NodeSetup.down
  end
end 

