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
    end
  end
end
