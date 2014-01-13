require 'debugger'
require 'pg'

module Nebula
  class Db
    NODE_TABLE_NAME = "nebula_nodes"
    EDGE_TABLE_NAME = "nebula_edges"

    def initialize(args = { })
      @host     = args.fetch(:host, 'localhost')
      @port     = args.fetch(:port, '5432')
      @dbname   = args.fetch(:dbname)
      @user     = args.fetch(:user)
      @password = args.fetch(:password)
    end

    def connect!
      @connection = PG.connect({
        host:     @host,
        port:     @port,
        dbname:   @dbname,
        user:     @user,
        password: @password
      })

      initialize_tables
    end

    private

      def initialize_tables
        unless table_exists?(NODE_TABLE_NAME)
          create_nodes_table
        end

        unless table_exists?(EDGE_TABLE_NAME)
          create_edges_table
        end
      end

      def table_exists?(table_name)
        sql = <<-SQL
          SELECT pg_tables.tablename FROM pg_tables
          WHERE pg_tables.tablename = $1
        SQL

        result = @connection.exec_params(sql, [ table_name ])

        !result.values.empty?
      end

      def create_nodes_table
        sql = <<-SQL
          CREATE TABLE #{NODE_TABLE_NAME} (
            id   SERIAL PRIMARY KEY,
            data json NOT NULL
          )
        SQL

        @connection.exec(sql)
      end

      def create_edges_table
        sql = <<-SQL
          CREATE TABLE #{EDGE_TABLE_NAME} (
            id           SERIAL PRIMARY KEY,
            label        varchar(80) NOT NULL,
            from_node_id integer     NOT NULL REFERENCES #{NODE_TABLE_NAME} ON DELETE CASCADE,
            to_node_id   integer     NOT NULL REFERENCES #{NODE_TABLE_NAME} ON DELETE CASCADE
          )
        SQL

        @connection.exec(sql)
      end
  end
end
