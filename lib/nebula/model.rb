require 'yajl'
require 'hashie'
require 'nebula'
require 'nebula/db'

module Nebula
  module Model

    @@db = nil

    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.db(options = { })
      if options.fetch(:recreate, false)
        @@db = nil
      end

      @@db ||= Nebula::Db.new(Nebula.database).tap do |db|
        db.connect!(options)
      end
    end

    class Params < Hash
      include Hashie::Extensions::MergeInitializer
      include Hashie::Extensions::IndifferentAccess
    end

    module ClassMethods
      def table
        raise NotImplementedError
      end

      def table_name
        Nebula::DB::TABLES[table]
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

      def create(params = { })
        if attrs = db.create(table, params)
          new(attrs)
        end
      end

      def find(id)
        if attrs = db.get(table, id)
          new(attrs)
        end
      end

      def count
        db.count(table)
      end

      def destroy_all
        db.truncate(table)
      end

      def indexes(&block)
        db.list_indexes(table).map(&(block || proc { |row| row }))
      end

      def index_names
        indexes { |row| row['indexname'] }
      end

      protected

        def cast_attributes(data, &block)
          (@attributes || { }).each do |name, klass|
            block.call(name, cast(data[name.to_s], klass))
          end
        end

        def cast(value, klass)
          return nil unless value

          if klass == Integer
            value.to_i

          elsif klass == String
            value.to_s

          elsif klass == Hash
            value.is_a?(Hash) ? value : Hash[Yajl::Parser.parse(value)]

          else
            value
          end
        end
    end

    def initialize(args = { })
      self.class.send(:cast_attributes, Params.new(args)) do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def ==(other)
      self.id == other.id
    end
  end
end
