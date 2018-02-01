require_relative "postgres/connection"
require_relative "postgres/functions"
require_relative "postgres/aggregates"

module VersionedDatabaseFunctions
  # VersionedDatabaseFunctions database adapters.
  #
  # VersionedDatabaseFunctions ships with a Postgres adapter only but can be extended with
  # additional adapters. The {Adapters::Postgres} adapter provides the
  # interface.
  module Adapters
    # An adapter for managing Postgres functions.
    #
    # These methods are used interally by VersionedDatabaseFunctions and are not intended for direct
    # use. Methods that alter database schema are intended to be called via
    # {Statements}.
    #
    # The methods are documented here for insight into specifics of how VersionedDatabaseFunctions
    # integrates with Postgres and the responsibilities of {Adapters}.
    class Postgres
      # Creates an instance of the VersionedDatabaseFunctions Postgres adapter.
      #
      # This is the default adapter for VersionedDatabaseFunctions. Configuring it via
      # {VersionedDatabaseFunctions.configure} is not required, but the example below shows how one
      # would explicitly set it.
      #
      # @param [#connection] connectable An object that returns the connection
      #   for VersionedDatabaseFunctions to use. Defaults to `ActiveRecord::Base`.
      #
      # @example
      #  VersionedDatabaseFunctions.configure do |config|
      #    config.database = VersionedDatabaseFunctions::Adapters::Postgres.new
      #  end
      def initialize(connectable = ActiveRecord::Base)
        @connectable = connectable
      end

      # Returns an array of functions in the database.
      #
      # This collection of functions is used by the [VersionedDatabaseFunctions::SchemaDumper] to
      # populate the `schema.rb` file.
      #
      # @return [Array<VersionedDatabaseFunctions::Function>]
      def functions
        Functions.new(connection).all
      end

      # Returns an array of aggregates in the database.
      #
      # This collection of aggregates is used by the [VersionedDatabaseFunctions::SchemaDumper] to
      # populate the `schema.rb` file.
      #
      # @return [Array<VersionedDatabaseFunctions::Aggregate>]
      def aggregates
        Aggregates.new(connection).all
      end

      # Creates a function in the database.
      #
      # This is typically called in a migration via {Statements#create_function}.
      #
      # @param name The name of the function to create
      # @param sql_definition The SQL schema for the function.
      #
      # @return [void]
      def create_function(name, arguments, returns_definition, sql_definition, language)
        execute "CREATE FUNCTION #{quote_table_name(name)}(#{arguments}) RETURNS #{returns_definition} AS $$ #{sql_definition} $$ LANGUAGE #{language};"
      end

      # Creates an aggregate function in the database.
      #
      # This is typically called in a migration via {Statements#create_aggregate_function}.
      #
      # @param name The name of the aggregate function to create
      # @param sql_definition The SQL schema for the function.
      #
      # @return [void]
      def create_aggregate(name, arguments, sql_definition)
        execute "CREATE AGGREGATE #{quote_table_name(name)}(#{arguments})(#{sql_definition});"
      end

      # Updates a function in the database.
      #
      # This results in a {#drop_function} followed by a {#create_function}. The
      # explicitness of that two step process is preferred to `CREATE OR
      # REPLACE FUNCTION` because the former ensures that the function you are trying to
      # update did, in fact, already exist.
      #
      # This is typically called in a migration via {Statements#update_function}.
      #
      # @param name The name of the function to update
      # @param sql_definition The SQL schema for the updated function.
      #
      # @return [void]
      def update_function(name, arguments, returns_definition, sql_definition, language)
        drop_function(name, arguments)
        create_function(name, arguments, returns_definition, sql_definition, language)
      end

      # Updates an aggregate in the database.
      #
      # This results in a {#drop_aggregate} followed by a {#create_aggregate}.
      #
      # This is typically called in a migration via {Statements#update_aggregate}.
      #
      # @param name The name of the function to update
      # @param sql_definition The SQL schema for the updated function.
      #
      # @return [void]
      def update_aggregate(name, arguments, sql_definition)
        drop_aggregate(name, arguments)
        create_aggregate(name, arguments, sql_definition)
      end

      # Replaces a function in the database using `CREATE OR REPLACE FUNCTION`.
      #
      # This results in a `CREATE OR REPLACE FUNCTION`. Most of the time the
      # explicitness of the two step process used in {#update_function} is preferred
      # to `CREATE OR REPLACE FUNCTION` because the former ensures that the function you
      # are trying to update did, in fact, already exist. Additionally,
      #
      # However, when there is a tangled dependency tree
      # `CREATE OR REPLACE FUNCTION` can be preferable.
      #
      # This is typically called in a migration via
      # {Statements#replace_function}.
      #
      # @param name The name of the function to update
      # @param sql_definition The SQL schema for the updated function.
      #
      # @return [void]
      def replace_function(name, arguments, returns_definition, sql_definition, language)
        execute "CREATE OR REPLACE FUNCTION #{quote_table_name(name)}(#{arguments}) RETURNS #{returns_definition} AS $$ #{sql_definition} $$ LANGUAGE #{language};"
      end

      # Drops the named function from the database
      #
      # This is typically called in a migration via {Statements#drop_function}.
      #
      # @param name The name of the function to drop
      #
      # @return [void]
      def drop_function(name, arguments)
        execute "DROP FUNCTION #{quote_table_name(name)}(#{arguments});"
      end

      # Drops the named aggregate from the database
      #
      # This is typically called in a migration via {Statements#drop_aggregate}.
      #
      # @param name The name of the aggregate to drop
      #
      # @return [void]
      def drop_aggregate(name, arguments)
        execute "DROP AGGREGATE #{quote_table_name(name)}(#{arguments});"
      end

      private

      attr_reader :connectable
      delegate :execute, :quote_table_name, to: :connection

      def connection
        Connection.new(connectable.connection)
      end

      def refresh_dependencies_for(name)
        VersionedDatabaseFunctions::Adapters::Postgres::RefreshDependencies.call(
          name,
          self,
          connection,
        )
      end
    end
  end
end
