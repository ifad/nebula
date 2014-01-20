require 'nebula/model'

module Nebula
  class Node
    include Model

    attribute :id,    Integer
    attribute :label, String
    attribute :data,  Hash

    class << self
      def table
        :nodes
      end

      def create_index(args = { })
        db.create_node_index(args.merge({
          on: Array(args.fetch(:on))
        }))
      end
    end
  end
end
