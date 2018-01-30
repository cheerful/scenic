require "rails/railtie"

module VersionedDatabaseFunctions
  # Automatically initializes VersionedDatabaseFunctions in the context of a Rails application when
  # ActiveRecord is loaded.
  #
  # @see VersionedDatabaseFunctions.load
  class Railtie < Rails::Railtie
    initializer "versioned_database_functions.load" do
      ActiveSupport.on_load :active_record do
        VersionedDatabaseFunctions.load
      end
    end
  end
end
