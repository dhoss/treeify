treeify
======
[![Build Status](https://travis-ci.org/dhoss/treeify.svg?branch=master)](https://travis-ci.org/dhoss/treeify)
[![Code Climate](https://codeclimate.com/github/dhoss/treeify/badges/gpa.svg)](https://codeclimate.com/github/dhoss/treeify)
[![Test Coverage](https://codeclimate.com/github/dhoss/treeify/badges/coverage.svg)](https://codeclimate.com/github/dhoss/treeify)
[![endorse](https://api.coderwall.com/dhoss/endorsecount.png)](https://coderwall.com/dhoss)
[![Dependency Status](https://gemnasium.com/dhoss/treeify.png)](https://gemnasium.com/dhoss/treeify)

Synopsis
========

  1. Create your migration
  ```
  create_table :nodes do |t|
    t.text :name
    t.integer :parent_id
    t.references :parent
  end
  add_index :nodes, [:parent_id, :id], :unique => true
  ```

  2. Create your model 
  ```
class Node < ActiveRecord::Base
  include Treeify
  config({:cols => [:name]})

  validates_uniqueness_of :name
  validates_uniqueness_of :parent_id, :scope=> :id
end
  ```
  3. Create a tree of stuff
  ```
parent = Node.create(name: "parent node")

parent.children << Node.new(name: "child 1")

parent.children.first.children << Node.new(name: "child 2")
  ```
  4. Retrieve tree of stuff
  ```
  parent.descendent_tree

  # which should give you something like this:
  [
    {
      "id"=>168,
      "name"=>"child 1",
      "parent_id"=>167,
      "children"=>
        [
          {
            "id"=>169, 
            "name"=>"child 2", 
            "parent_id"=>168, 
            "children"=>[]
          }
        ]
    }
  ]

  ```
  
  
The SQL Generated looks something like this: 
  
  ```
   SELECT "nodes".* FROM "nodes"  WHERE (nodes.id IN (WITH RECURSIVE cte (id, path)  AS (
         SELECT  id,
           array[id] AS path
         FROM    nodes
         WHERE   id = 8

         UNION ALL

         SELECT  nodes.id,
            cte.path || posts.id
         FROM    nodes
         JOIN cte ON nodes.parent_id = cte.id
       )
       SELECT id FROM cte
       ORDER BY path))  ORDER BY posts.id
  ```

I haven't done much in terms of benchmarking, but it seems like using a join would be better than using an IN() clause here.  I'm looking to improve this in future versions.
  
  
API
====
  
  In the spirit of keeping things simple, Treeify does just a few things:
  
   1. Provides a ```has_many :children``` relationship which is a self-join that allows you to collect the direct descendents of any node.
   2. On  the flip side, it provides a ``belongs_to :parent``` relationship to get a node's parent, if one exists
   3. The ```roots``` scope, which retrieves all parent records (their ```parent_id``` is null)
   4. ```config``` Allows you to pass in custom column names to be retrieved.  THIS WILL CHANGE as "config" isn't nearly generic enough to not cause conflicts with other libraries.
   5. ```descendents``` Retrieves direct descendents of a node
   6. ```descendent_tree``` Returns an array of hashes containing a tree-like structure of a given node's descendents and sub-descendents.
  
License
=======
The MIT License (MIT)

Copyright (c) [year] [fullname]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
