module VersionedDatabaseFunctions
  # Methods that are made available in migrations for managing VersionedDatabaseFunctions views.
  module Statements
    # Create a new database function.
    #
    # @param name [String, Symbol] The name of the database function.
    # @param arguments [String, Symbol] The arguments for the function.
    # @param returns [String, Symbol] The definiton of what the function returns.
    # @param language [String, Symbol] The language of the function body. This defaults to `:sql` if not provided.
    # @param version [Fixnum] The version number of the function, used to find the
    #   definition file in `db/functions`. This defaults to `1` if not provided.
    # @param sql_definition [String] The SQL query for the function body. An error
    #   will be raised if `sql_definition` and `function` are both set,
    #   as they are mutually exclusive.
    # @return The database response from executing the create statement.
    #
    # @example Create from `db/functions/moving_average_v02.sql`
    #   create_function(:sum, arguments: "integer, integer", returns: "integer", language: :sql, version: 2)
    #
    # @example Create from provided SQL string
    #   create_function(:moving_average, arguments: "integer, integer", returns: "integer", language: :sql, sql_definition: <<-SQL
    #     SELECT $1 + $2
    #   SQL
    #   )
    #
    def create_function(name, arguments:, returns:, language: :sql, version: nil, sql_definition: nil)
      if version.present? && sql_definition.present?
        raise(
          ArgumentError,
          "sql_definition and version cannot both be set",
        )
      end

      if version.blank? && sql_definition.blank?
        version = 1
      end

      sql_definition ||= function_definition(name, version)

      VersionedDatabaseFunctions.database.create_function(name, arguments, returns, sql_definition, language)
    end

    # Drop a database function by name and signature.
    #
    # @param name [String, Symbol] The name of the database function.
    # @param arguments [String, Symbol] The arguments used for this database function.
    # @param revert_to_version [Fixnum] Used to reverse the `drop_function` command
    #   on `rake db:rollback`. The provided version will be passed as the
    #   `version` argument to {#create_function}.
    # @return The database response from executing the drop statement.
    #
    # @example Drop a function, rolling back to version 3 on rollback
    #   drop_function(:moving_average, revert_to_version: 3)
    #
    def drop_function(name, arguments:, returns:, revert_to_version: nil)
      VersionedDatabaseFunctions.database.drop_function(name, arguments)
    end

    # Update a database function to a new version.
    #
    # The existing function is dropped and recreated using the supplied `version`
    # parameter.
    #
    # @param name [String, Symbol] The name of the database function.
    # @param arguments [String, Symbol] The arguments for the function.
    # @param returns [String, Symbol] The definiton of what the function returns.
    # @param language [String, Symbol] The language of the function body. This defaults to `:sql` if not provided.
    # @param version [Fixnum] The version number of the function.
    # @param sql_definition [String] The SQL query for the function schema. An error
    #   will be raised if `sql_definition` and `version` are both set,
    #   as they are mutually exclusive.
    # @param revert_to_version [Fixnum] The version number to rollback to on
    #   `rake db rollback`
    # @return The database response from executing the create statement.
    #
    # @example
    #   update_function :sum, arguments: "integer, integer", returns: "integer", language: :sql, version: 3, revert_to_version: 2
    #
    def update_function(name, arguments:,returns:, language: :sql, version: nil, sql_definition: nil, revert_to_version: nil)
      if version.blank? && sql_definition.blank?
        raise(
          ArgumentError,
          "sql_definition or version must be specified",
        )
      end

      if version.present? && sql_definition.present?
        raise(
          ArgumentError,
          "sql_definition and version cannot both be set",
        )
      end

      sql_definition ||= function_definition(name, version)

      VersionedDatabaseFunctions.database.update_function(name, arguments, returns, sql_definition, language)
    end

    # Update a database function to a new version using `CREATE OR REPLACE FUNCTION`.
    #
    # The existing function is replaced using the supplied `version`
    # parameter.
    #
    # @param name [String, Symbol] The name of the database view.
    # @param arguments [String, Symbol] The arguments for the function.
    # @param returns [String, Symbol] The definiton of what the function returns.
    # @param language [String, Symbol] The language of the function body. This defaults to `:sql` if not provided.
    # @param version [Fixnum] The version number of the function.
    # @param revert_to_version [Fixnum] The version number to rollback to on
    #   `rake db rollback`
    # @return The database response from executing the create statement.
    #
    # @example
    #   replace_function :sum, arguments: "integer, integer", returns: "integer", language: :sql, version: 3, revert_to_version: 2
    #
    def replace_function(name, arguments:,returns:, language: :sql, version: nil, revert_to_version: nil)
      if version.blank?
        raise ArgumentError, "version is required"
      end

      sql_definition = function_definition(name, version)

      VersionedDatabaseFunctions.database.replace_function(name, arguments, returns, sql_definition, language)
    end

    # Create a new database aggregate.
    #
    # @param name [String, Symbol] The name of the database aggregate.
    # @param arguments [String, Symbol] The arguments for the aggregate.
    # @param version [Fixnum] The version number of the aggregate, used to find the
    #   definition file in `db/aggregates`. This defaults to `1` if not provided.
    # @param sql_definition [String] The SQL query for the aggregate body. An error
    #   will be raised if `sql_definition` and `aggregate` are both set,
    #   as they are mutually exclusive.
    # @return The database response from executing the create statement.
    #
    # @example Create from `db/aggregates/moving_average_v02.sql`
    #   create_aggregate(:sum, arguments: "integer, integer", returns: "integer", language: :sql, version: 2)
    #
    # @example Create from provided SQL string
    #   create_aggregate(:moving_average, arguments: "integer, integer", returns: "integer", language: :sql, sql_definition: <<-SQL
    #     SELECT $1 + $2
    #   SQL
    #   )
    #
    def create_aggregate(name, arguments:, version: nil)
      if version.blank?
        version = 1
      end

      sql_definition = aggregate_definition(name, version)

      VersionedDatabaseFunctions.database.create_aggregate(name, arguments, sql_definition)
    end

    # Drop a database aggregate by name and signature.
    #
    # @param name [String, Symbol] The name of the database aggregate.
    # @param arguments [String, Symbol] The arguments used for this database aggregate.
    # @param revert_to_version [Fixnum] Used to reverse the `drop_aggregate` command
    #   on `rake db:rollback`. The provided version will be passed as the
    #   `version` argument to {#create_aggregate}.
    # @return The database response from executing the drop statement.
    #
    # @example Drop a aggregate, rolling back to version 3 on rollback
    #   drop_aggregate(:moving_average, revert_to_version: 3)
    #
    def drop_aggregate(name, arguments:, revert_to_version: nil)
      VersionedDatabaseFunctions.database.drop_aggregate(name, arguments)
    end

    # Update a database aggregate to a new version.
    #
    # The existing aggregate is dropped and recreated using the supplied `version`
    # parameter.
    #
    # @param name [String, Symbol] The name of the database aggregate.
    # @param arguments [String, Symbol] The arguments for the aggregate.
    # @param version [Fixnum] The version number of the aggregate.
    # @param sql_definition [String] The SQL query for the aggregate schema. An error
    #   will be raised if `sql_definition` and `version` are both set,
    #   as they are mutually exclusive.
    # @param revert_to_version [Fixnum] The version number to rollback to on
    #   `rake db rollback`
    # @return The database response from executing the create statement.
    #
    # @example
    #   update_aggregate :sum, arguments: "integer, integer", returns: "integer", language: :sql, version: 3, revert_to_version: 2
    #
    def update_aggregate(name, arguments:,version: nil, revert_to_version: nil)
      if version.blank?
        raise(
          ArgumentError,
          "version must be specified",
        )
      end

      sql_definition = aggregate_definition(name, version)

      VersionedDatabaseFunctions.database.update_aggregate(name, arguments, sql_definition)
    end

    private

    def function_definition(name, version)
      VersionedDatabaseFunctions::Definitions::Function.new(name, version).to_sql
    end

    def aggregate_definition(name, version)
      VersionedDatabaseFunctions::Definitions::Aggregate.new(name, version).to_sql
    end
  end
end
