module VersionedDatabaseFunctions
  module Adapters
    class Postgres
      # Fetches defined aggregates from the postgres connection.
      # @api private
      class Aggregates
        def initialize(connection)
          @connection = connection
        end

        # All of the aggregates that this connection has defined.
        #
        # This will include aggregate aggregates if those are supported by the
        # connection.
        #
        # @return [Array<VersionedDatabaseFunctions::Function>]
        def all
          aggregates_from_postgres.map(&method(:to_versioned_database_functions_aggregate))
        end

        private

        attr_reader :connection

        def aggregates_from_postgres
          connection.execute(<<-SQL)
            SELECT n.nspname as namespace,
              p.proname as aggregatename,
              pg_catalog.pg_get_function_result(p.oid) as result_data_type,
              pg_catalog.pg_get_function_arguments(p.oid) as argument_data_types,
             CASE
              WHEN p.proisagg THEN 'aggregate'
              WHEN p.proiswindow THEN 'window'
              WHEN p.prorettype = 'pg_catalog.trigger'::pg_catalog.regtype THEN 'trigger'
              ELSE 'normal'
             END as kind,
             p.prosrc as source_code,
             l.lanname as language
            FROM pg_catalog.pg_proc p
                 LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
                 LEFT JOIN pg_catalog.pg_language l ON l.oid = p.prolang
            WHERE pg_catalog.pg_function_is_visible(p.oid)
                  AND n.nspname <> 'pg_catalog'
                  AND n.nspname <> 'information_schema'
                  AND (p.proisagg = true)
            ORDER BY 1, 2, 4;
          SQL
        end

        def to_versioned_database_functions_aggregate(result)
          namespace, aggregatename = result.values_at "namespace", "aggregatename"

          if namespace != "public"
            namespaced_aggregatename = "#{pg_identifier(namespace)}.#{pg_identifier(aggregatename)}"
          else
            namespaced_aggregatename = pg_identifier(aggregatename)
          end

          VersionedDatabaseFunctions::Aggregate.new(
            name: namespaced_aggregatename,
            kind: result["kind"],
            arguments: result["argument_data_types"],
            source_code: result["source_code"].strip,
            language: result["language"],
          )
        end

        def pg_identifier(name)
          return name if name =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/
          PGconn.quote_ident(name)
        end
      end
    end
  end
end
