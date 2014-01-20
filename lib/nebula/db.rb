require 'pg'
require 'yajl'

module Nebula
  class Db

    TABLES = {
      nodes: 'nebula_nodes',
      edges: 'nebula_edges'
    }.freeze

    class ConnectionParams < Hash
      def inspect
        "#<Nebula::Db::ConnectionParams>"
      end
    end

    def initialize(args = { })
      @connection_params = ConnectionParams[{
        host:     args.fetch(:host, 'localhost'),
        port:     args.fetch(:port, 5432),
        dbname:   args.fetch(:dbname),
        user:     args.fetch(:user),
        password: args.fetch(:password)
      }]
    end

    def connect!(options = { })
      @connection = PG.connect(@connection_params)

      # silence notices
      @connection.set_notice_receiver  { }

      if status = (@connection.status == PG::CONNECTION_OK)
        initialize_tables(options.fetch(:recreate, false))
      end

      status
    end

    def create(table, args = { })
      case table
        when :nodes then create_node(args)
        when :edges then create_edge(args)
      end
    end

    def create_node(args = { })
      insert(:nodes, {
        label: args.fetch(:label),
        data:  Yajl::Encoder.encode(args.fetch(:data))
      })
    end

    def create_edge(args = { })
      insert(:edges, {
        label:        args.fetch(:label),
        from_node_id: args.fetch(:from_node_id),
        to_node_id:   args.fetch(:to_node_id)
      })
    end

    def get(table, id)
      select(table, [ [ 'id', '=', id ] ]).first
    end

    def count(table)
      select(table, [ ], select: 'COUNT(*)').first['count'].to_i
    end

    # index nodes on JSON in 'data' column.
    # :on   is either a list of keys
    # :path specifies that the list of keys is a JSON path (default true)
    #   when false, a multi-column index is created, provided :type does
    #   not conflict.
    # :name is an optional index name
    # :type is the optional type of index to use, for example :hash
    #
    # example: create an index on all nodes that have
    # the 'foo' key
    # create_node_index(on: [ 'foo' ], type: :hash)
    #
    def create_node_index(args = { })
      case (on = args.delete(:on))
        when Array then create_node_index_on_keys(on, args)
        else
          raise ArgumentError, "invalid value for :on"
      end
    end

    # list all indexes on the given table
    def list_indexes(table)
      @connection.exec(%{ SELECT * FROM pg_indexes WHERE tablename = '#{TABLES[table]}' })
    end

    def truncate(table)
      @connection.exec(%{ TRUNCATE TABLE #{TABLES[table]} CASCADE })
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

      def select(table, conds = [ ], options = { })
        sql = <<-SQL
          SELECT #{options.fetch(:select, '*')} FROM #{TABLES[table]}
        SQL

        unless conds.empty?
          sql << <<-SQL
            WHERE (#{conds.each_with_index.map { |(key, op, _), i| "#{key} #{op} $#{i + 1}" }.join(' AND ')})
          SQL
        end

        @connection.exec(sql, conds.map { |(_, _, val)| val })
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

        @connection.exec(sql).result_status == PG::PGRES_COMMAND_OK
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
  end
end
