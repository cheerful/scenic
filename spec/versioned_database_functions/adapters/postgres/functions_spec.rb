require "spec_helper"

module VersionedDatabaseFunctions
  module Adapters
    describe Postgres::Functions, :db do
      it "returns versioned_database_functions function objects for plain old functions" do
        connection = ActiveRecord::Base.connection
        connection.execute <<-SQL
          CREATE FUNCTION add_em(integer, integer) RETURNS integer AS $$ SELECT $1 + $2; $$ LANGUAGE SQL;
        SQL

        views = Postgres::Functions.new(connection).all
        first = views.first

        expect(views.size).to eq 1
        expect(first.name).to eq "add_em"
        expect(first.kind).to eq "normal"
        expect(first.arguments).to eq "integer, integer"
        expect(first.result_data_type).to eq "integer"
        expect(first.language).to eq "sql"
        expect(first.source_code).to eq "SELECT $1 + $2;"
      end
    end
  end
end
