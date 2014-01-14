require 'pg'
require 'yajl'

module Nebula
  class Db
    TABLES = {
      nodes: 'nebula_nodes',
      edges: 'nebula_edges'
    }.freeze

    def initialize(args = { })
      @host     = args.fetch(:host, 'localhost')
      @port     = args.fetch(:port, '5432')
      @dbname   = args.fetch(:dbname)
      @user     = args.fetch(:user)
      @password = args.fetch(:password)
    end

    def connect!(options = { })
      @connection = PG.connect({
        host:     @host,
        port:     @port,
        dbname:   @dbname,
        user:     @user,
        password: @password
      })

      if status = (@connection.status == PG::CONNECTION_OK)
        initialize_tables(options.fetch(:recreate, false))
      end

      status
    end

    def create_node(label, args = { })
      insert(:nodes, {
        label: label,
        data:  Yajl::Encoder.encode(args.fetch(:data))
      })
    end

    def create_edge(label, args = { })
      insert(:edges, {
        label:        label,
        from_node_id: args.fetch(:from).id,
        to_node_id:   args.fetch(:to).id
      })
    end

    # index nodes on JSON in 'data' column.
    # :on   is either a list of keys
    # :path specifies that the list of keys is a JSON path (default true)
    # :name is an optional index name
    # :type is the optional type of index to use, for example :hash
    #
    # example: create an index on all nodes that have
    # the 'foo' key
    # create_node_index(on: [ 'foo' ], type: :hash)
    #
    # example: create an index on all nodes that have
    # a 'bar' key with the value 'baz'
    # create_node_index(on: { 'bar' => 'baz' })
    #
    def create_node_index(args = { })
      case (on = args.delete(:on))
        when Array then create_node_index_on_keys(on, args)
        else
          raise ArgumentError, "invalid value for :on"
      end
    end

    def node_indexes
      @connection.exec(%{ SELECT * FROM pg_indexes WHERE tablename = '#{TABLES[:nodes]}' })
    end

    protected

      def insert(table, attributes = { })
        sql = <<-SQL
          INSERT INTO #{TABLES[table]} (#{attributes.keys.join(', ')})
          VALUES (#{attributes.length.times.map { |t| "$#{t + 1}" }.join(", ")})
          RETURNING *
        SQL

        result = @connection.exec(sql, attributes.values)

        result[0]
      end

      def create_node_index_on_keys(keys = [ ], options = { })
        if keys.empty?
          raise ArgumentError, "no keys given"
        end

        name = options[:name] ? "#{TABLES[:nodes]}_#{options[:name]}" : ""
        type = options[:type] ? "USING #{options[:type]}"        : ""

        sql  = %{ CREATE INDEX #{name} ON #{TABLES[:nodes]} #{type} }

        if options.fetch(:path, true) && keys.length > 1
          sql << "((data#>>'{#{keys.join(', ')}}'))"
        else
          sql << "((#{keys.map { |k| "data->>'#{k}'" }.join('), (')}))"
        end

        @connection.exec(sql)
      end

    private

      def initialize_tables(recreate = false)
        [ :nodes, :edges ].each do |table|
          if (exists = table_exists?(table)) && recreate
            drop_table(table)
            exists = false
          end

          unless exists
            create_table(table)
            create_index(table, :label, type: :hash)
          end
        end
      end

      def table_exists?(table)
        sql = <<-SQL
          SELECT pg_tables.tablename FROM pg_tables
          WHERE pg_tables.tablename = $1
        SQL

        result = @connection.exec_params(sql, [ TABLES[table] ])

        !result.values.empty?
      end

      def create_table(table)
        send("create_#{table}")
      end

      def drop_table(table)
        sql = <<-SQL
          DROP TABLE #{TABLES[table]} CASCADE
        SQL

        @connection.exec(sql)
      end

      def create_nodes
        sql = <<-SQL
          CREATE TABLE #{TABLES[:nodes]} (
            id    SERIAL PRIMARY KEY,
            label varchar(80) NOT NULL,
            data  json            NULL
          )
        SQL

        @connection.exec(sql)
      end

      def create_edges
        sql = <<-SQL
          CREATE TABLE #{TABLES[:edges]} (
            id           SERIAL PRIMARY KEY,
            label        varchar(80) NOT NULL,
            from_node_id integer     NOT NULL REFERENCES #{TABLES[:nodes]} ON DELETE CASCADE,
            to_node_id   integer     NOT NULL REFERENCES #{TABLES[:nodes]} ON DELETE CASCADE
          )
        SQL

        @connection.exec(sql)
      end

      def create_index(table, column, options = { })
        name = options.fetch(:name, "index_on_#{TABLES[table]}_#{column}")

        if options[:type]
          @connection.exec("CREATE INDEX #{name} ON #{TABLES[table]} USING #{options[:type]} (#{column})")
        else
          @connection.exec("CREATE INDEX #{name} ON #{TABLES[table]} (#{column})")
        end
      end

      def to_hash(result)

      end
  end
end
