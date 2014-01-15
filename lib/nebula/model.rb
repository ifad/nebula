require 'yajl'
require 'nebula'
require 'nebula/db'

module Nebula
  module Model

    @@db = nil

    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.db(options = { })
      @@db ||= Nebula::Db.new(Nebula.database).tap do |db|
        db.connect!
      end
    end

    module ClassMethods
      def table
        raise NotImplementedError
      end

      def db
        Model.db
      end

      def attribute(name, klass)
        (@attributes ||= { })[name] = klass
        class_eval do
          attr_reader name
        end
      end

      def create(label, params = { })
        new(cast_attributes(db.create(table, label, params)))
      end

      def destroy_all
        db.truncate(table)
      end

      protected

        def cast_attributes(data)
          (@attributes || { }).inject({ }) do |attrs, (name, klass)|
            attrs.merge(name => cast(data[name.to_s], klass))
          end
        end

        def cast(value, klass)
          if klass == Integer
            value.to_i

          elsif klass == String
            value.to_s

          elsif klass == Hash
            Hash[Yajl::Parser.parse(value)]

          else
            value
          end
        end
    end

    def initialize(args = { })
      args.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end
end
