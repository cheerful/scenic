require "versioned_database_functions/command_recorder/statement_arguments"

module VersionedDatabaseFunctions
  # @api private
  module CommandRecorder
    def create_function(*args)
      record(:create_function, args)
    end

    def drop_function(*args)
      record(:drop_function, args)
    end

    def update_function(*args)
      record(:update_function, args)
    end

    def replace_function(*args)
      record(:replace_function, args)
    end

    def invert_create_function(args)
      [:drop_function, args]
    end

    def invert_drop_function(args)
      perform_versioned_database_functions_inversion(:create_function, args)
    end

    def invert_update_function(args)
      perform_versioned_database_functions_inversion(:update_function, args)
    end

    def invert_replace_function(args)
      perform_versioned_database_functions_inversion(:replace_function, args)
    end

    def create_aggregate(*args)
      record(:create_aggregate, args)
    end

    def drop_aggregate(*args)
      record(:drop_aggregate, args)
    end

    def update_aggregate(*args)
      record(:update_aggregate, args)
    end

    def invert_create_aggregate(args)
      [:drop_aggregate, args]
    end

    def invert_drop_aggregate(args)
      perform_versioned_database_functions_inversion(:create_aggregate, args)
    end

    def invert_update_aggregate(args)
      perform_versioned_database_functions_inversion(:update_aggregate, args)
    end

    def invert_replace_aggregate(args)
      perform_versioned_database_functions_inversion(:replace_aggregate, args)
    end

    private

    def perform_versioned_database_functions_inversion(method, args)
      versioned_database_functions_args = StatementArguments.new(args)

      if versioned_database_functions_args.revert_to_version.nil?
        message = "#{method} is reversible only if given a revert_to_version"
        raise ActiveRecord::IrreversibleMigration, message
      end

      [method, versioned_database_functions_args.invert_version.to_a]
    end
  end
end
