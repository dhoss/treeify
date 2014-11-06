require 'rubygems'
require 'active_record'
require 'active_record/migration'
require_relative "../lib/treeify"
require 'benchmark'
include Benchmark   

ActiveRecord::Base.establish_connection(
  :adapter => 'postgresql',
  :database => 'tree_test',
  :username => 'postgres'
)

class Node < ActiveRecord::Base
  include Treeify

  validates_uniqueness_of :name
  validates_uniqueness_of :parent_id, :scope=> :id
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
NodeSetup.up
nodes = []

puts "Creating records..."
10.times do |i|
  nodes[i] = []
  parent = Node.create(name: "root_#{i}")
  10.times do |j|
    node = Node.new(name: "node_#{i}_#{j}")
    _parent = nodes[i][rand(nodes[i].size)] || parent
    node.parent_id = _parent.id
    node.save
    nodes[i] << node
  end
end
puts "Created #{Node.count} records"

puts "Running benchmark..."
Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |x|
  fb   = x.report("find_by_sql:") { Node.roots.first.descendents * 1000 }
  w_in = x.report("where in:")   { Node.roots.first.descendents2 * 1000 }
  [fb+w_in, (fb+w_in)/2]
end
NodeSetup.down
