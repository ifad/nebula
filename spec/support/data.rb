module Nebula
  module SpecSupport
    module Data
      def create_nebula
        # find by label
        Node.create(label: 'foo', data: { verified: true })
        Node.create(label: 'baz')
        Node.create(label: 'bot')

        # find by data attribute
        Node.create(label: 'foobarbarbaz',  data: { foo: 'bar', bar: 'baz' })
        Node.create(label: 'foobarbarbot',  data: { foo: 'bar', bar: 'bot' })
        Node.create(label: 'foo5',          data: { foo: 5 })
        Node.create(label: 'foostring5',    data: { foo: '5' })
        Node.create(label: 'foo5.2',        data: { foo: 5.2 })
        Node.create(label: 'foostring5.2',  data: { foo: '5.2' })
        Node.create(label: 'deepfoobarbaz', data: { foo: { bar: 'baz' } })

        # find by incoming/outgoing edge label
        root = Node.create(label: 'root')
        root.link(Node.create(label: 'in_one'), 'foo')
        root.link(Node.create(label: 'in_two'), 'foo')
        root.link(Node.create(label: 'in_three'), 'bar')

        # connection specs
        root_a = Node.create(label: 'root_a')
        root_b = Node.create(label: 'root_b')

        internal_a = Node.create(label: 'internal_a')
        internal_b = Node.create(label: 'internal_b')

        leaf_a = Node.create(label: 'leaf_a')
        leaf_b = Node.create(label: 'leaf_b')
        leaf_c = Node.create(label: 'leaf_c')

        root_a.link(internal_a, 'internal')
        root_a.link(internal_b, 'internal')
        root_b.link(internal_a, 'internal')

        internal_a.link(leaf_a, 'leaf')
        internal_a.link(leaf_b, 'leaf')
        internal_b.link(leaf_c, 'leaf')
      end
    end
  end
end

