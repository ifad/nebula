require 'nebula/db'
require 'nebula/node'
require 'nebula/edge'
require 'hashie'

module Nebula
  class Query

    #
    # :query is a "node query" hash, which has the
    # following keys, all of which are optional:
    #   - label: a string to match against node labels
    #   - data:  a "data query" hash for matching against node data
    #   - in:    an "edge query" hash for matching against incoming edges
    #   - out:   an "edge query" hash for matching against outgoing edges
    #
    # an "edge query" hash has the following structure
    #   - label: a string to match against edge labels
    #   - from:  a "node query" hash for matching against edge "from" nodes
    #   - to:    a "node query" hash for matching against edge "to" nodes
    #
    # a "data query" hash has the following structure:
    #   - a single hash or array of hashes
    #   - hash keys are "AND"ed, and arrays are "OR"ed
    #   - hash values are deeply traversed
    #
    # AND example:
    #  { foo: 'bar', baz: 'bot' } =>
    #  ((data->>'foo' = 'bar') AND (data->>'baz' = 'bot'))
    #
    # OR example:
    #  [ { foo: 'bar' }, { foo: 'baz' } ] =>
    #  ((data->>'foo' = 'bar') OR (data->>'foo' = 'baz'))
    #
    # Deep traversal example:
    #   [ { foo: { bar: 'baz' } }, { bot: 'flimdar' } ] =>
    #   ((data#>>'{foo,bar}' = 'baz') OR (data->>'bot' = 'fimadar'))
    #
    # Another deep traversal example:
    #   [ { foo: { bar: { 5 : [ 'a', 'b', c' ] } } } ] =>
    #   ((data#>>'{foo,bar,5}' IN ('a', 'b', 'c'))
    #
    def initialize(query = { })
      @query = NodeQuery.new(query, "*")
    end

    def to_sql
      @query.to_sql
    end

    def exec
      Node.db.exec(to_sql)
    end

    protected

      def nodes
        self.class.send(:nodes)
      end

      class QueryHash < Hash
        include Hashie::Extensions::MergeInitializer
        include Hashie::Extensions::KeyConversion
      end

      class NodeQuery
        def initialize(query = { }, select = "id")
          @query  = QueryHash.new(query).symbolize_keys
          @select = select
          @label  = @query[:label]
          @data   = (@query[:data] ? DataQuery.new(@query[:data]) : nil)

          @in  = (@query[:in]  ? EdgeQuery.new(@query[:in],  :in)  : nil)
          @out = (@query[:out] ? EdgeQuery.new(@query[:out], :out) : nil)
        end

        def to_sql
          select = "SELECT #{Node.table_name}.#{@select} FROM #{Node.table_name}"
          conds  = [ ]

          if @label
            conds.push("(#{Node.table_name}.label = '#{Db.escape(@label)}')")
          end

          if @data
            conds.push(@data.to_sql)
          end

          if @in
            conds.push("(#{Node.table_name}.id IN (#{@in.to_sql}))")
          end

          if @out
            conds.push("(#{Node.table_name}.id IN (#{@out.to_sql}))")
          end

          if conds.empty?
            select
          else
            [ select, "WHERE", conds.join(" AND ") ].join(" ")
          end
        end
      end

      class EdgeQuery
        def initialize(query = { }, direction)
          @label     = query[:label]
          @from      = query[:from] ? NodeQuery.new(query[:from]) : nil
          @to        = query[:to]   ? NodeQuery.new(query[:to])   : nil
          @direction = direction
        end

        def to_sql
          select = ""
          conds  = [ ]

          case @direction
            when :in  then select << "SELECT #{Edge.table_name}.to_node_id FROM #{Edge.table_name}"
            when :out then select << "SELECT #{Edge.table_name}.from_node_id FROM #{Edge.table_name}"
          end

          if @label
            conds.push("(#{Edge.table_name}.label = '#{Db.escape(@label)}')")
          end

          if @from
            conds.push("(#{Edge.table_name}.from_node_id IN (#{@from.to_sql}))")
          end

          if @to
            conds.push("(#{Edge.table_name}.to_node_id IN (#{@to.to_sql}))")
          end

          if conds.empty?
            select
          else
            [ select, "WHERE", conds.join(" AND ") ].join(" ")
          end
        end
      end

      class DataQuery
        def initialize(query = { })
          @query = query
        end

        def to_sql
          return "" if @query.empty?

          ors = (@query.is_a?(Array) ? @query : [ @query ]).map do |hash|
            ands = hash.map do |key, value|
              selector(key, value)
            end

            if ands.length > 1
              "((" + ands.join(") AND (") + "))"
            else
              "(#{ands.first})"
            end
          end

          if ors.length > 1
            "(" + ors.join(" OR ") + ")"
          else
            ors.first
          end
        end

        private

          def selector(path, value)

            path = Array(path)

            if value.respond_to?(:each_pair)
              value.map do |sub_path, sub_value|
                selector(path + [ sub_path ], sub_value)
              end.join(') AND (')

            elsif value.respond_to?(:join)
              "#{operator(path)} IN (#{value.map(&method(:cast)).join(', ')})"

            else
              "#{operator(path)} = #{cast(value)}"
            end
          end

          def quote(v)
            if v.is_a?(Numeric)
              v
            else
              "'#{v}'"
            end
          end

          # must compare json values as text,
          # but numbers are not strings, and vice-versa
          # (see the operator method)
          def cast(value)
            if value.is_a?(Numeric)
              "'#{value}'"
            else
              "'\"#{value}\"'"
            end
          end

          # we have to select json values and then cast
          # to text instead of using the 'as text' operator
          # in order to distinguish between numbers
          # and strings.
          # for example:
          #   ('{ "a" : 1, "b" : 2 }'::json->'b')::text => 2
          #   but
          #   '{ "a" : 1, "b", "2" }'::json->'b'::text => "2"
          #   whereas
          #   '{ "a" : 1, "b" : 2 }'::json->>'b' => 2
          #   and
          #   '{ "a" : 1, "b" : "2" }'::json->>'b' => 2
          def operator(path)
            if path.length == 1
              "(#{Node.table_name}.data->#{quote(path.first)})::text"
            else
              "(#{Node.table_name}.data#>'{#{path.join(',')}}')::text"
            end
          end
      end
  end
end
