require 'active_record'
require 'pp'
require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/class/attribute"

module Treeify
  extend ActiveSupport::Concern

  cattr_writer :cols do 
    []
  end

  included do
    has_many :children,
             class_name: self,
             foreign_key: "parent_id"
    belongs_to :parent,
                class_name: self,
                foreign_key: "parent_id"

    class_attribute :cols
    scope :roots, -> { where(parent_id: nil) }
    scope :tree_for, ->(instance) { self.find_by_sql self.tree_sql_for(instance) }
    scope :tree_for_ancestors, ->(instance) { self.find_by_sql self.tree_sql_for_ancestors(instance) }
  end

  module ClassMethods
    
    def tree_config(hash = {})
      self.cols = !hash[:cols].nil? == true ? hash[:cols] : []
    end

    def columns_joined(char=",")
      self.cols ||= []
      self.cols.join(char)
    end

    def columns_with_table_name
      self.cols ||= []
      self.cols.map{|c| 
        c = "#{table_name}.#{c}" 
      }.join(",")
    end

    def has_config_defined_cols?
      #return true if self.respond_to?("cols") && !self.cols.nil? 
      if self.respond_to?("cols")
        return !self.cols.empty? if !self.cols.nil?
      end
      false
    end

    # sort of hacky, but check to see if we have any columns defined in the config
    # if we do, return the string of columns, formatted appropriately
    # otherwise, just return an empty string
    def appropriate_column_listing(columns = columns_joined)
      has_config_defined_cols? == true ? ", #{columns}" : ""
    end

    def tree_sql(instance)
      cte_params = has_config_defined_cols? ? "id, parent_id, path, #{columns_joined}" : "id, parent_id, path"

      "WITH RECURSIVE cte (#{cte_params})  AS (
         SELECT  id,
           parent_id,
           array[id] AS path#{appropriate_column_listing}
         FROM    #{table_name}
         WHERE   id = #{instance.id}

         UNION ALL

         SELECT  #{table_name}.id,
            #{table_name}.parent_id,
            cte.path || #{table_name}.id#{appropriate_column_listing(columns_with_table_name)}
         FROM    #{table_name}
         JOIN cte ON #{table_name}.parent_id = cte.id
       )"
    end

    def tree_sql_for(instance)
      "#{tree_sql(instance)}
       SELECT * FROM cte
       ORDER BY path"
    end

    def tree_sql_for_ancestors(instance)
      "#{tree_sql(instance)}
      SELECT * FROM cte 
      WHERE cte.id != #{instance.id}"
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
