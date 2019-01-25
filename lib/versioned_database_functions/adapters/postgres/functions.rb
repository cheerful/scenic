module VersionedDatabaseFunctions
  module Adapters
    class Postgres
      # Fetches defined functions from the postgres connection.
      # @api private
      class Functions
        def initialize(connection)
          @connection = connection
        end

        # All of the functions that this connection has defined.
        #
        # This will include aggregate functions if those are supported by the
        # connection.
        #
        # @return [Array<VersionedDatabaseFunctions::Function>]
        def all
          functions_from_postgres.map(&method(:to_versioned_database_functions_function))
        end

        private

        attr_reader :connection

        def functions_from_postgres
          connection.execute(<<-SQL)
            SELECT n.nspname as namespace,
              p.proname as functionname,
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
                  AND (p.proisagg = false AND p.prorettype <> 'pg_catalog.trigger'::pg_catalog.regtype)
                  AND LOWER(l.lanname) != 'c'
            ORDER BY 1, 2, 4;
          SQL
        end

        def to_versioned_database_functions_function(result)
          namespace, functionname = result.values_at "namespace", "functionname"

          if namespace != "public"
            namespaced_functionname = "#{pg_identifier(namespace)}.#{pg_identifier(functionname)}"
          else
            namespaced_functionname = pg_identifier(functionname)
          end

          VersionedDatabaseFunctions::Function.new(
            name: namespaced_functionname,
            kind: result["kind"],
            arguments: result["argument_data_types"],
            result_data_type: result["result_data_type"],
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
