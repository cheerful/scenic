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
        self.class.path(filename)
      end

      def version
        @version.to_s.rjust(2, "0")
      end

      def self.latest_version(name)
        filenames = []
        search_name = filename(name, "*")
        Dir.chdir(Rails.root) { filenames = Dir.glob(path(search_name)) }
        raise RuntimeError, "No definition files for Aggregate" if filenames.empty?
        filenames.sort.last.scan(/v(\d+).sql/).first.first.to_i
      end

      private

      def self.path(name)
        File.join("db", "aggregates", name)
      end

      def self.filename(name, version)
        "#{name}_v#{version}.sql"
      end

      def filename
        self.class.filename(@name, version)
      end
    end
  end
end
