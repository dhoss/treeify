require 'active_record'
require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/class/attribute"

module SimpleTree
  extend ActiveSupport::Concern 

  module ClassMethods
    mattr_accessor :table_name
    mattr_accessor :cols

    def config(hash = {})
      # apparently columns is a reserved word in rails
      self.cols       = hash[:columns]
      self.table_name = hash[:table_name]
    end

    def query 
      "WITH RECURSIVE cte (id, #{self.cols.join(',')}, path, parent_id, depth)  AS (
         SELECT  id,
          #{self.cols.join(',')}
           array[id] AS path,
           parent_id,
           1 AS depth
         FROM    #{self.table_name}
         WHERE   parent_id IS NULL

         UNION ALL

         SELECT  #{self.table_name}.id,
            #{self.cols.map{ |c| self.table_name << '.' << c }.join(',')},
            #{self.table_name}.author,
            cte.path || #{self.table_name}.id,
            #{self.table_name}.parent_id,
            cte.depth + 1 AS depth
         FROM    #{self.table_name}
         JOIN cte ON #{self.table_name}.parent_id = cte.id
       )
       SELECT id, #{self.cols.join(',')}, path, depth FROM cte
       ORDER BY path;"
    end
  end

  module InstanceMethods
  end
end 
