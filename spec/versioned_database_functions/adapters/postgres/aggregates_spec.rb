require "spec_helper"

module VersionedDatabaseFunctions
  module Adapters
    describe Postgres::Aggregates, :db do
      it "returns versioned_database_functions aggregate objects for plain old functions" do
        connection = ActiveRecord::Base.connection
        connection.execute <<-SQL
          CREATE AGGREGATE "custom_function"(int)(
            sfunc = int4pl, stype = int,initcond = 10
          )
        SQL

        aggregates = Postgres::Aggregates.new(connection).all
        first = aggregates.first

        expect(aggregates.size).to eq 1
        expect(first.name).to eq "custom_function"
        expect(first.kind).to eq "aggregate"
        expect(first.arguments).to eq "integer"
        expect(first.language).to eq "internal"
        expect(first.source_code).to eq "aggregate_dummy"
      end
    end
  end
end
