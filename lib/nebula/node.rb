require 'nebula/model'

module Nebula
  class Node
    include Model

    set_table :nodes
    attribute :data, Hash

    class << self
      def create_index(args = { })
        db.create_node_index(args.merge({
          on: Array(args.fetch(:on))
        }))
      end

      def query(query = { })
        Query.new(query).exec.map(&method(:new))
      end
    end

    def link(other, label = "")
      Edge.create({
        from_node_id: self.id,
        to_node_id:   other.id,
        label:        label
      })
    end

    def data=(value)
      super(value || { })
    end

    def save
      self.data ||= { }
      super
    end
  end
end
