require "versioned_database_functions/command_recorder/statement_arguments"

module VersionedDatabaseFunctions
  # @api private
  module CommandRecorder
    def create_view(*args)
      record(:create_view, args)
    end

    def drop_view(*args)
      record(:drop_view, args)
    end

    def update_view(*args)
      record(:update_view, args)
    end

    def replace_view(*args)
      record(:replace_view, args)
    end

    def invert_create_view(args)
      [:drop_view, args]
    end

    def invert_drop_view(args)
      perform_versioned_database_functions_inversion(:create_view, args)
    end

    def invert_update_view(args)
      perform_versioned_database_functions_inversion(:update_view, args)
    end

    def invert_replace_view(args)
      perform_versioned_database_functions_inversion(:replace_view, args)
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
