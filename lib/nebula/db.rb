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

    protected

      def insert(table, attributes = { })
        sql = <<-SQL
          INSERT INTO #{TABLES[table]} (#{attributes.keys.join(', ')})
          VALUES (#{attributes.length.times.map { |t| "$#{t + 1}" }.join(", ")})
          RETURNING id
        SQL

        result = @connection.exec(sql, attributes.values)

        attributes.merge(id: result[0]['id'])
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
