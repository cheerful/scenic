module VersionedDatabaseFunctions
  module Adapters
    class Postgres
      # Decorates an ActiveRecord connection with methods that help determine
      # the connections capabilities.
      #
      # Every attempt is made to use the versions of these methods defined by
      # Rails where they are available and public before falling back to our own
      # implementations for older Rails versions.
      #
      # @api private
      class Connection < SimpleDelegator
        # An integer representing the version of Postgres we're connected to.
        #
        # postgresql_version is public in Rails 5, but protected in earlier
        # versions.
        #
        # @return [Integer]
        def postgresql_version
          if undecorated_connection.respond_to?(:postgresql_version)
            super
          else
            undecorated_connection.send(:postgresql_version)
          end
        end

        private

        def undecorated_connection
          __getobj__
        end
      end
    end
  end
end
