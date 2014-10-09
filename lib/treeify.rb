require 'active_record'
require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/class/attribute"

module Treeify
  extend ActiveSupport::Concern 

  included do
    has_many :children,
             class_name: self,
             foreign_key: "parent_id"
    belongs_to :parent,
                class_name: self,
                foreign_key: "parent_id"
    class_attribute :cols
    scope :roots, -> { where(parent_id: nil) }
    scope :tree_for, ->(instance) { where("#{table_name}.id IN (#{tree_sql_for(instance)})").order("#{table_name}.id") }
    scope :tree_for_ancestors, ->(instance) { where("#{table_name}.id IN (#{tree_sql_for_ancestors(instance)})").order("#{table_name}.id") }
  end

  module ClassMethods

    def config(hash = {})
      # apparently columns is a reserved word in rails
      self.cols       = hash[:cols]
    end

    def tree_sql(instance)
      "WITH RECURSIVE cte (id, path)  AS (
         SELECT  id,
           array[id] AS path
         FROM    #{table_name}
         WHERE   id = #{instance.id}

         UNION ALL

         SELECT  #{table_name}.id,
            cte.path || #{table_name}.id
         FROM    #{table_name}
         JOIN cte ON #{table_name}.parent_id = cte.id
       )"
    end

    def tree_sql_for(instance)
      "#{tree_sql(instance)}
       SELECT id FROM cte
       ORDER BY path"
    end

    def tree_sql_for_ancestors(instance)
      "WITH RECURSIVE cte (id, path)  AS (
         SELECT  id,
           array[id] AS path
         FROM    #{table_name}
         WHERE   id = #{instance.id}
         
         UNION ALL

         SELECT  #{table_name}.id,
            cte.path || #{table_name}.id
         FROM    #{table_name}
         JOIN cte ON #{table_name}.parent_id = cte.id
       )
      SELECT cte.id FROM cte WHERE cte.id != #{instance.id}"
    end
  end
        
  def descendents
    self_and_descendents - [self]
  end

  def ancestors
    self.class.tree_for_ancestors(self)
  end

  def self_and_descendents
    self.class.tree_for(self)
  end

  def is_root?
    self.parent_id != nil
  end

  def siblings
    self.class.where(parent_id: self.parent_id) - [self]
  end

  def descendent_tree
    # give build_tree an array of hashes with the AR objects serialized into a hash
    build_tree(descendents.to_a.map(&:serializable_hash))
  end

  def build_tree(data)
    # turn our AoH into a hash where we've mapped the ID column
    # to the rest of the hash + a comments array for nested comments
    nested_hash = Hash[data.map{|e| [e['id'], e.merge('children' => [])]}]

    # if we have a parent ID, grab all the comments
    # associated with that parent and push them into the comments array
    nested_hash.each do |id, item|
      parent = nested_hash[item['parent_id']]
      parent['children'] << item if parent
    end

    # return the values of our nested hash, ie our actual comment hash data
    # reject any descendents whose parent ID already exists in the main hash so we don't
    # get orphaned descendents listed as their own comment
     
    nested_hash.reject{|id, item| 
      nested_hash.has_key? item['parent_id']
    }.values
  end
end 
