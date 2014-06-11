require 'active_record'
require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/class/attribute"

module Treeify
  extend ActiveSupport::Concern 

  included do
    class_attribute :cols
    scope :roots, -> { where(parent_id: nil) }
    scope :tree_for, -> (instance) { where("#{table_name}.id IN (#{tree_sql_for(instance)})").order("#{table_name}.id") }
  end

  module ClassMethods

    def config(hash = {})
      # apparently columns is a reserved word in rails
      self.cols       = hash[:cols]
    end

    def tree_sql_for(instance)
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
       SELECT id FROM cte
       ORDER BY path"
    end
  end
        
  def descendents
    self_and_descendents - [self]
  end

  def self_and_descendents
    self.class.tree_for(self)
  end
end 
