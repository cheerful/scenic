require "rails/generators"
require "rails/generators/active_record"
require "generators/versioned_database_functions/arguments"

module VersionedDatabaseFunctions
  module Generators
    # @api private
    class AggregateGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      include VersionedDatabaseFunctions::Generators::Arguments
      source_root File.expand_path("../templates", __FILE__)

      def create_aggregates_directory
        unless aggregates_directory_path.exist?
          empty_directory(aggregates_directory_path)
        end
      end

      def create_aggregate_definition
        if creating_new_aggregate?
          create_file definition.path
        else
          copy_file previous_definition.full_path, definition.full_path
        end
      end

      def create_migration_file
        if creating_new_aggregate? || destroying_initial_aggregate?
          migration_template(
            "db/migrate/create_aggregate.erb",
            "db/migrate/create_#{normalized_file_name}.rb",
          )
        else
          migration_template(
            "db/migrate/update_aggregate.erb",
            "db/migrate/update_#{normalized_file_name}_to_version_#{version}.rb",
          )
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def previous_version
          @previous_version ||=
            Dir.entries(aggregates_directory_path)
              .map { |name| version_regex.match(name).try(:[], "version").to_i }
              .max
        end

        def version
          @version ||= destroying? ? previous_version : previous_version.next
        end

        def migration_class_name
          if creating_new_aggregate?
            "Create#{class_name.gsub('.', '')}"
          else
            "Update#{class_name}ToVersion#{version}"
          end
        end

        def activerecord_migration_class
          if ActiveRecord::Migration.respond_to?(:current_version)
            "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
          else
            "ActiveRecord::Migration"
          end
        end
      end

      private

      def aggregates_directory_path
        @aggregates_directory_path ||= Rails.root.join(*%w(db aggregates))
      end

      def version_regex
        /\A#{normalized_file_name}_v(?<version>\d+)\.sql\z/
      end

      def creating_new_aggregate?
        previous_version == 0
      end

      def definition
        VersionedDatabaseFunctions::Definitions::Aggregate.new(normalized_file_name, version)
      end

      def previous_definition
        VersionedDatabaseFunctions::Definitions::Aggregate.new(normalized_file_name, previous_version)
      end

      def normalized_file_name
        @normalized_file_name ||= file_name.gsub(".", "_")
      end

      def destroying?
        behavior == :revoke
      end

      def formatted_name
        if file_name.include?(".")
          "\"#{file_name}\""
        else
          ":#{file_name}"
        end
      end

      def destroying_initial_aggregate?
        destroying? && version == 1
      end
    end
  end
end
