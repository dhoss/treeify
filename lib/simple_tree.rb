module SimpleTree

  # Returns all ancestors of the current node.
  def ancestors
    query =
    "(WITH RECURSIVE crumbs AS (
          SELECT #{self.table_name}.*,

          1 AS depth

          FROM #{self.table_name}

          WHERE id = #{id} 

          UNION ALL

          SELECT alias1.*, 

          depth + 1 

          FROM crumbs

          JOIN #{self.table_name} alias1 ON alias1.id = crumbs.parent_id

        ) SELECT * FROM crumbs WHERE crumbs.id != #{id}) as #{self.table_name}"

      self.send(:with_exclusive_scope) do
        self.scoped(
          :from => query,
          :order => "#{self.table_name}.depth DESC"
        )
      end
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
  # This method will accept two parameters.
  #   * :raw -> Result is scope that can more finders can be chained against with additional 'level' attribute
  #   * {:depth => n} -> Will only search for descendants to the given depth of n
  # NOTE: You can restrict results by depth on the scope returned, but better performance will be
  # gained by specifying it within the args so it will be applied during the recursion, not after.
  def descendants(*args)
    args.delete_if{|x| !x.is_a?(Hash) && x != :raw}
    self.nodes_and_descendants(:no_self, self, *args)
  end

  # Returns the depth of the current node. 0 depth represents the root of the tree
  def depth
    query =
    "WITH RECURSIVE crumbs AS (
          SELECT parent_id, 0 AS level

          FROM #{self.table_name}

          WHERE id = #{self.id} 

          UNION ALL

          SELECT alias1.parent_id, level + 1 

          FROM crumbs

          JOIN #{self.table_name} alias1 ON alias1.id = crumbs.parent_id

        ) SELECT level FROM crumbs ORDER BY level DESC LIMIT 1"

    ActiveRecord::Base.connection.select_all(query).first.try(:[], 'level').try(:to_i)
end
