require "rails"

module VersionedDatabaseFunctions
  # @api private
  module SchemaDumper
    def tables(stream)
      super
      functions(stream)
      aggregates(stream)
    end

    def functions(stream)
      if dumpable_functions_in_database.any?
        stream.puts
      end

      dumpable_functions_in_database.each do |function|
        stream.puts(function.to_schema)
      end
    end

    def aggregates(stream)
      if dumpable_aggregates_in_database.any?
        stream.puts
      end

      dumpable_aggregates_in_database.each do |aggregate|
        stream.puts(aggregate.to_schema)
      end
    end

    private

    def dumpable_functions_in_database
      @dumpable_functions_in_database ||= VersionedDatabaseFunctions.database.functions.reject do |function|
        ignored?(function.name)
      end
    end

    def dumpable_aggregates_in_database
      @dumpable_aggregates_in_database ||= VersionedDatabaseFunctions.database.aggregates.reject do |aggregate|
        ignored?(aggregate.name)
      end
    end

    unless ActiveRecord::SchemaDumper.private_instance_methods(false).include?(:ignored?)
      # This method will be present in Rails 4.2.0 and can be removed then.
      def ignored?(table_name)
        ["schema_migrations", ignore_tables].flatten.any? do |ignored|
          case ignored
          when String; remove_prefix_and_suffix(table_name) == ignored
          when Regexp; remove_prefix_and_suffix(table_name) =~ ignored
          else
            raise StandardError, "ActiveRecord::SchemaDumper.ignore_tables accepts an array of String and / or Regexp values."
          end
        end
      end
    end
  end
end
