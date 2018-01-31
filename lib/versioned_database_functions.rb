require "versioned_database_functions/configuration"
require "versioned_database_functions/adapters/postgres"
require "versioned_database_functions/command_recorder"
require "versioned_database_functions/definitions/function"
require "versioned_database_functions/definitions/aggregate"
require "versioned_database_functions/railtie"
require "versioned_database_functions/schema_dumper"
require "versioned_database_functions/statements"
require "versioned_database_functions/version"
require "versioned_database_functions/function"
require "versioned_database_functions/index"

# VersionedDatabaseFunctions adds methods `ActiveRecord::Migration` to create and manage database
# views in Rails applications.
module VersionedDatabaseFunctions
  # Hooks VersionedDatabaseFunctions into Rails.
  #
  # Enables versioned_database_functions migration methods, migration reversability, and `schema.rb`
  # dumping.
  def self.load
    ActiveRecord::ConnectionAdapters::AbstractAdapter.include VersionedDatabaseFunctions::Statements
    ActiveRecord::Migration::CommandRecorder.include VersionedDatabaseFunctions::CommandRecorder
    ActiveRecord::SchemaDumper.prepend VersionedDatabaseFunctions::SchemaDumper
  end

  # The current database adapter used by VersionedDatabaseFunctions.
  #
  # This defaults to {Adapters::Postgres} but can be overridden
  # via {Configuration}.
  def self.database
    configuration.database
  end
end
