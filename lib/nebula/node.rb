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
    end
  end
end
