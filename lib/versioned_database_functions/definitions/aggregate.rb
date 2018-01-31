module VersionedDatabaseFunctions
  module Definitions
    # @api private
    class Aggregate
      def initialize(name, version)
        @name = name
        @version = version.to_i
      end

      def to_sql
        File.read(full_path).tap do |content|
          if content.empty?
            raise "Define aggregate body in #{path} before migrating."
          end
        end
      end

      def full_path
        Rails.root.join(path)
      end

      def path
        File.join("db", "aggregates", filename)
      end

      def version
        @version.to_s.rjust(2, "0")
      end

      private

      def filename
        "#{@name}_v#{version}.sql"
      end
    end
  end
end
