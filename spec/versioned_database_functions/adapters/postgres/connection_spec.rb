require "spec_helper"

module VersionedDatabaseFunctions
  module Adapters
    describe Postgres::Connection do
      describe "#postgresql_version" do
        it "uses the public method on the provided connection if defined" do
          base_connection = Class.new do
            def postgresql_version
              123
            end
          end

          connection = Postgres::Connection.new(base_connection.new)

          expect(connection.postgresql_version).to eq 123
        end

        it "uses the protected method if the underlying method is not public" do
          base_connection = Class.new do
            protected

            def postgresql_version
              123
            end
          end

          connection = Postgres::Connection.new(base_connection.new)

          expect(connection.postgresql_version).to eq 123
        end
      end
    end
  end
end
