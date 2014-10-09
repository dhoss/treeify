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

child = parent.children.create(name: "child 1")

child2 = child.children.create(name: "child 2")
```

4. Retrieve tree of stuff

```
parent.descendent_tree
```

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