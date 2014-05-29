require 'active_record'
require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"

module SimpleTree
  extend ActiveSupport::Concern 

  

  included do
@config = {
    :order       => nil,
    :foreign_key => :parent_id,
    :max_depth   => 10000,
    :dependant   => :destroy
  }
    has_many :children,
      class_name: self.name,
      foreign_key: :parent_id,
      dependent: :destroy
    belongs_to :parent,
      class_name: self.name,
      foreign_key: :parent_id
    scope :roots, -> { 
      where("#{@config[:foreign_key]} IS NULL").order(@config[:order])
    }


  end

    # Returns all ancestors of the current node.
    def ancestors
      query =
      "(WITH RECURSIVE crumbs AS (
            SELECT #{self.class.table_name}.*,

            1 AS depth

            FROM #{self.class.table_name}

            WHERE id = #{id} 

            UNION ALL

            SELECT alias1.*, 

            depth + 1 

            FROM crumbs

            JOIN #{self.class.table_name} alias1 ON alias1.id = crumbs.parent_id

          ) SELECT * FROM crumbs WHERE crumbs.id != #{id}) as #{self.class.table_name}"

      self.send(:with_exclusive_scope) do
        self.scoped(
          :from => query,
          :order => "#{self.class.table_name}.depth DESC"
        )
      end
    end

    # Returns the root node of the tree.
    def root
      ancestors.first
    end

    

    # Returns all siblings of the current node.
    #
    #   subchild1.siblings # => [subchild2]
    def siblings
      self_and_siblings - [self]
    end

    # Returns all siblings and a reference to the current node.
    #
    #   subchild1.self_and_siblings # => [subchild1, subchild2]
    def self_and_siblings
      parent ? parent.children : self.roots
    end

    # Returns if the current node is a root
    def root?
      parent_id.nil?
    end

    # Returns all descendants of the current node. Each level
    # is within its own hash, so for a structure like:
    #   root
    #    \_ child1
    #         \_ subchild1
    #               \_ subsubchild1
    #         \_ subchild2
    # the resulting hash would look like:
    #
    #  {child1 =>
    #    {subchild1 =>
    #      {subsubchild1 => {}},
    #     subchild2 => {}}}
    #
    # This method will accept one parameter.
    #   * {:depth => n} -> Will only search for descendants to the given depth of n
    # NOTE: You can restrict results by depth on the scope returned, but better performance will be
    # gained by specifying it within the args so it will be applied during the recursion, not after.
    def descendants(*args)
      args.delete_if{|x| !x.is_a?(Hash) && x != :raw}
      self.nodes_and_descendants(:no_self, self, *args)
    end
  
    # args:: ActiveRecord models or IDs - Symbols: :raw, :no_self - Hash: {:to_depth => n, :at_depth => n}
    # Returns provided nodes plus all descendants of provided nodes in nested Hash where keys are nodes and values are children
    # :raw:: return value will be flat array
    # :no_self:: Do not include provided nodes in result
    # Hash:
    #   :to_depth:: Only retrieve values to given depth
    #   :at_depth:: Only retrieve values from given depth
    def nodes_and_descendants(*args)
      raw = args.delete(:raw)
      no_self = args.delete(:no_self)
      at_depth = nil
      depth = nil
      hash = args.detect{|x|x.is_a?(Hash)}
      if(hash)
        args.delete(hash)
        depth = hash[:depth] || hash[:to_depth]
        at_depth = hash[:at_depth]
      end
      depth ||= @config[:max_depth].to_i
      depth_restriction = "WHERE crumbs.depth + 1 < #{depth}" if depth
      depth_clause = nil
      if(at_depth)
        depth_clause = "#{self.class.table_name}.depth + 1 = #{at_depth.to_i + 1}"
      elsif(depth)
        depth_clause = "#{self.class.table_name}.depth + 1 < #{depth.to_i + 2}"
      end
      base_ids = args.map{|x| x.is_a?(ActiveRecord::Base) ? x.id : x.to_i}
      query = 
        "(WITH RECURSIVE crumbs AS (
          SELECT #{self.class.table_name}.*, #{no_self ? -1 : 0} AS depth FROM #{self.class.table_name} WHERE #{base_ids.empty? ? 'parent_id IS NULL' : "id in (#{base_ids.join(', ')})"}
          UNION ALL
          SELECT alias1.*, crumbs.depth + 1 FROM crumbs JOIN #{self.class.table_name} alias1 on alias1.parent_id = crumbs.id
          #{depth_restriction}
        ) SELECT * FROM crumbs) as #{self.class.table_name}"
        q = self.scoped(
          :from => query, 
          :conditions => "#{self.class.table_name}.depth >= 0"
        )
      if(@config[:order].present?)
        q = q.scoped(:order => @config[:order])
      end
      if(depth_clause)
        q = q.scoped(:conditions => depth_clause)
      end
      res = ActiveSupport::OrderedHash.new
      cache = ActiveSupport::OrderedHash.new
      q.all.each do |item|
        res[item] = ActiveSupport::OrderedHash.new
        cache[item] = res[item]
      end
      cache.each_pair do |item, values|
        if(cache[item.parent])
          cache[item.parent][item] = values
          res.delete(item)
        end
      end
      res
    end
    
    # src:: Array of nodes
    # chk:: Array of nodes
    # Return true if any nodes within chk are found within src
    def nodes_within?(src, chk)
      s = (src.is_a?(Array) ? src : [src]).map{|x|x.is_a?(ActiveRecord::Base) ? x.id : x.to_i}
      c = (chk.is_a?(Array) ? chk : [chk]).map{|x|x.is_a?(ActiveRecord::Base) ? x.id : x.to_i}
      if(s.empty? || c.empty?)
        false
      else
        q = self.connection.select_all(
          "WITH RECURSIVE crumbs AS (
            SELECT #{self.class.table_name}.*, 0 AS level FROM #{self.class.table_name} WHERE id in (#{s.join(', ')})
            UNION ALL
            SELECT alias1.*, crumbs.level + 1 FROM crumbs JOIN #{self.class.table_name} alias1 on alias1.parent_id = crumbs.id
          ) SELECT count(*) as count FROM crumbs WHERE id in (#{c.join(', ')})"
        )
        q.first['count'].to_i > 0
      end
    end

    # src:: Array of nodes
    # chk:: Array of nodes
    # Return all nodes that are within both chk and src
    def nodes_within(src, chk)
      s = (src.is_a?(Array) ? src : [src]).map{|x|x.is_a?(ActiveRecord::Base) ? x.id : x.to_i}
      c = (chk.is_a?(Array) ? chk : [chk]).map{|x|x.is_a?(ActiveRecord::Base) ? x.id : x.to_i}
      if(s.empty? || c.empty?)
        nil
      else
        query = 
          "(WITH RECURSIVE crumbs AS (
            SELECT #{self.class.table_name}.*, 0 AS depth FROM #{self.class.table_name} WHERE id in (#{s.join(', ')})
            UNION ALL
            SELECT alias1.*, crumbs.depth + 1 FROM crumbs JOIN #{self.class.table_name} alias1 on alias1.parent_id = crumbs.id
            #{@config[:max_depth] ? "WHERE crumbs.depth + 1 < #{@config[:max_depth].to_i}" : ''}
          ) SELECT * FROM crumbs WHERE id in (#{c.join(', ')})) as #{self.class.table_name}"
          self.scoped(:from => query)
       end
    end

    # Returns the depth of the current node. 0 depth represents the root of the tree
    def depth
      query =
      "WITH RECURSIVE crumbs AS (
            SELECT parent_id, 0 AS level

            FROM #{self.class.table_name}

            WHERE id = #{self.id} 

            UNION ALL

            SELECT alias1.parent_id, level + 1 

            FROM crumbs

            JOIN #{self.class.table_name} alias1 ON alias1.id = crumbs.parent_id

      ) SELECT level FROM crumbs ORDER BY level DESC LIMIT 1"
      ActiveRecord::Base.connection.select_all(query).first.try(:[], 'level').try(:to_i)
    end
end 
