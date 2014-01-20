require 'yajl'
require 'hashie'
require 'nebula'
require 'nebula/db'

module Nebula
  module Model

    @@db = nil

    def self.included(base)
      base.extend(ClassMethods)

      # set up common attributes
      base.class_eval do
        attribute :id,    Integer
        attribute :label, String
      end
    end

    def self.db(options = { })
      if options.fetch(:recreate, false)
        @@db = nil
      end

      @@db ||= Nebula::Db.new(Nebula.database).tap do |db|
        db.connect!(options)
      end
    end

    class Data < Hash
      include Hashie::Extensions::MergeInitializer
      include Hashie::Extensions::IndifferentAccess
      include Hashie::Extensions::KeyConversion

      def initialize(args = { })
        if args.is_a?(String)
          super(Yajl::Parser.parse(args))
        else
          super(args)
        end

        stringify_keys!
      end
    end

    module ClassMethods
      def table
        @table || raise("table not set")
      end

      def set_table(t)
        @table = t.to_sym
      end

      def table_name
        Nebula::DB::TABLES[table]
      end

      def db
        Model.db
      end

      def attribute(name, klass)
        raise ArgumentError unless name
        raise ArgumentError unless klass

        (@attributes ||= { })[name] = klass

        # dynamically include a module to contain these
        # methods, so we can override them if need be

        mod = Module.new do
          define_method(name) do
            instance_variable_get("@#{name}")
          end

          define_method("#{name}=") do |value|
            instance_variable_set("@#{name}", self.class.send(:cast, value, klass))
          end
        end

        include mod
      end

      def attributes
        @attributes ? @attributes.dup : { }
      end

      def create(params = { })
        new(params).save
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

        def cast(value, klass)
          return nil unless value

          if klass == Integer
            value.to_i

          elsif klass == String
            value.to_s

          elsif klass == Hash
            Data.new(value)

          else
            value
          end
        end
    end

    def initialize(args = { })
      args.each do |key, value|
        send("#{key}=", value)
      end
    end

    def ==(other)
      self.id == other.id
    end

    def attributes
      self.class.attributes.keys.inject({ }) do |params, key|
        params.merge(key.to_sym => self.send(key))
      end
    end

    def save
      self.id = self.class.db.create(self.class.table, self.attributes)['id']
      return self
    end
  end
end
