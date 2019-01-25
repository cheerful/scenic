require "spec_helper"

module VersionedDatabaseFunctions
  module Adapters
    describe Postgres::Functions, :db do
      it "returns versioned_database_functions function objects for plain old functions" do
        connection = ActiveRecord::Base.connection
        connection.execute <<-SQL
          CREATE FUNCTION add_em(integer, integer) RETURNS integer AS $$ SELECT $1 + $2; $$ LANGUAGE SQL;
        SQL

        functions = Postgres::Functions.new(connection).all
        first = functions.first

        expect(functions.size).to eq 1
        expect(first.name).to eq "add_em"
        expect(first.kind).to eq "normal"
        expect(first.arguments).to eq "integer, integer"
        expect(first.result_data_type).to eq "integer"
        expect(first.language).to eq "sql"
        expect(first.source_code).to eq "SELECT $1 + $2;"
      end

      it "does not return C functions" do
        connection = ActiveRecord::Base.connection
        connection.execute <<-SQL
          CREATE EXTENSION pg_trgm; -- The easiest way to get C functions is to install pg_trgrm
        SQL

        functions = Postgres::Functions.new(connection).all

        functions.each do |function|
          expect(function.language).not_to eq "c"
        end
      end
    end
  end
end
