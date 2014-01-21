#!/usr/bin/env ruby

require 'nebula'
require 'nebula/node'
require 'nebula/edge'

Nebula.log_path = File.expand_path("../../nebula.log", __FILE__)
Nebula.database = { dbname: 'nebula', user: 'nebula', password: 'nebula' }

puts "Nebula.log_path: #{Nebula.log_path.inspect}"

# create a bunch of 'foo' nodes
# create a bunch of 'bar' nodes and connect them randomly to foos
# create of bunch of 'baz' nodes and connection the randomly to bars
#
names = ('AA'..'BZ').to_a

create_bazes = proc do |node|
  node.tap do
    names.each do |code|
      Nebula::Edge.create({
        label: 'Bar',
        from:   node,
        to:     Nebula::Node.create(label: code, data: { baz_id: code })
      })
    end
  end
end

create_bars = proc do |node|
  node.tap do
    names.each do |code|
      Nebula::Edge.create({
        label: 'Bar',
        from:   node,
        to:     create_bazes[Nebula::Node.create(label: code)]
      })
    end
  end
end

create_foos = proc do |node|
  node.tap do
    names.each do |code|
      puts "Foo: #{code}"
      Nebula::Edge.create({
        label: 'Foo',
        from:  node,
        to:    create_bars[Nebula::Node.create(label: code, data: { foo_id: code })]
      })
    end
  end
end



root = Nebula::Node.create(label: 'Root')

# first, create the ones we're looking for
foo = Nebula::Node.create(label: 'Foo', data: { foo_id: 'FO' })
bar = Nebula::Node.create(label: 'Bar')
baz = Nebula::Node.create(label: 'Baz', data: { baz_id: 'BAZ' })

Nebula::Edge.create(label: 'Foo', from: root, to: foo)
Nebula::Edge.create(label: 'Bar', from: foo,  to: bar)
Nebula::Edge.create(label: 'Baz', from: bar,  to: baz)

create_foos[root]
create_bars[foo]
create_bazes[bar]
