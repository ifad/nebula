require 'nebula/model'

module Nebula
  class Edge
    include Model

    set_table :edges
    attribute :from_node_id, Integer
    attribute :to_node_id,   Integer

    def from_node=(node)
      self.from_node_id = node.id
    end

    def to_node=(node)
      self.to_node_id = node.id
    end

    alias_method :from=, :from_node=
    alias_method :to=,   :to_node=

    def from_node
      Nebula::Node.find(self.from_node_id)
    end

    def to_node
      Nebula::Node.find(self.to_node_id)
    end

    alias_method :from, :from_node
    alias_method :to,   :to_node
  end
end

