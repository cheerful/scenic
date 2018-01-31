require "spec_helper"

module VersionedDatabaseFunctions
  module Adapters
    describe Postgres, :db do
      describe "#create_function" do
        it "successfully creates a function" do
          adapter = Postgres.new

          adapter.create_function("add_em", "integer, integer", "integer", "SELECT $1 + $2;", "SQL")

          expect(adapter.functions.map(&:name)).to include("add_em")
        end

        it "successfully creates functions with the same name, but separate signatures" do
          adapter = Postgres.new

          adapter.create_function("add_em", "integer, integer", "integer", "SELECT $1 + $2;", "SQL")
          adapter.create_function("add_em", "float, float", "float", "SELECT $1 + $2;", "SQL")

          expect(adapter.functions.select{|x| x.name == "add_em"}.map(&:arguments).to_set).to eql [
            "integer, integer",
            "double precision, double precision"
          ].to_set
        end

        it "successfully creates functions with no arguments" do
          adapter = Postgres.new

          adapter.create_function("one", "", "integer", "SELECT 1", "SQL")

          expect(adapter.functions.map(&:name)).to include("one")
        end

        it "breaks if trying to create an existing function" do
          adapter = Postgres.new

          adapter.create_function("add_em", "integer, integer", "integer", "SELECT $1 + $2;", "SQL")
          expect{
            adapter.create_function("add_em", "integer, integer", "integer", "SELECT $1 + $2;", "SQL")
          }.to raise_error(ActiveRecord::StatementInvalid, /PG::DuplicateFunction: ERROR:  function "add_em" already exists with same argument types/)
        end
      end

      describe "#create_aggregate" do
        it "successfully creates an aggregate" do
          adapter = Postgres.new

          adapter.create_aggregate(
            "custom_avg",
            "float8",
            "sfunc = float8_accum,
             stype = float8[],
             finalfunc = float8_avg,
             initcond = '{0,0,0}'"
          )

          function = adapter.functions.first
          expect(function.name).to eq("custom_avg")
          expect(function.kind).to eq "aggregate"
        end

        it "successfully creates aggregates with the same name, but separate signatures" do
          adapter = Postgres.new

          adapter.create_aggregate(
            "custom_function",
            "float8",
            "sfunc = float8_accum,
             stype = float8[],
             finalfunc = float8_avg,
             initcond = '{0,0,0}'"
          )

          adapter.create_aggregate(
            "custom_function",
            "int",
            "sfunc = int4pl,
             stype = int,
             initcond = 10"
          )

          expect(adapter.functions.select{|x| x.name == "custom_function"}.map(&:arguments).to_set).to eql [
            "integer", "double precision"
          ].to_set
        end

        it "breaks if trying to create an existing aggregate" do
          adapter = Postgres.new

          definition = "sfunc = float8_accum, stype = float8[], finalfunc = float8_avg, initcond = '{0,0,0}'"
          adapter.create_aggregate("custom_avg", "float8", definition)

          expect{
            adapter.create_aggregate("custom_avg", "float8", definition)
          }.to raise_error(ActiveRecord::StatementInvalid, /PG::DuplicateFunction: ERROR:  function "custom_avg" already exists with same argument types/)
        end
      end

      describe "#replace_function" do
        it "successfully replaces a function" do
          adapter = Postgres.new

          adapter.create_function("add_em", "integer, integer", "integer", "SELECT $1 + $2;", "SQL")

          function = adapter.functions.first.source_code
          expect(function).to eql "SELECT $1 + $2;"

          adapter.replace_function("add_em", "integer, integer", "integer", "SELECT $1 + $2 + 3;", "SQL")

          function = adapter.functions.first.source_code
          expect(function).to eql "SELECT $1 + $2 + 3;"
        end
      end

      describe "#update_function" do
        it "successfully replaces a function" do
          adapter = Postgres.new

          adapter.create_function("add_em", "integer, integer", "integer", "SELECT $1 + $2;", "SQL")

          function = adapter.functions.first.source_code
          expect(function).to eql "SELECT $1 + $2;"

          adapter.update_function("add_em", "integer, integer", "integer", "SELECT $1 + $2 + 3;", "SQL")

          function = adapter.functions.first.source_code
          expect(function).to eql "SELECT $1 + $2 + 3;"
        end
      end

      describe "#update_aggregate" do
        it "successfully replaces an aggregate function" do
          adapter = Postgres.new

          adapter.create_aggregate(
            "custom_avg",
            "float8",
            "sfunc = float8_accum,
             stype = float8[],
             finalfunc = float8_avg,
             initcond = '{0,0,0}'"
          )

          result = adapter.execute("SELECT custom_avg(num) FROM (VALUES (1), (2), (3)) AS x(num);")
          expect(result[0]["custom_avg"]).to eql 2.0

          new_source_code = "sfunc = float8_accum,
             stype = float8[],
             finalfunc = float8_avg,
             initcond = '{2,2,3}'"

          adapter.update_aggregate("custom_avg", "float8",new_source_code)

          result = adapter.execute("SELECT custom_avg(num) FROM (VALUES (1), (2), (3)) AS x(num);")
          expect(result[0]["custom_avg"]).to eql 1.6
        end
      end

      describe "#drop_function" do
        it "successfully drops a function" do
          adapter = Postgres.new

          adapter.create_function("add_em", "integer, integer", "integer", "SELECT $1 + $2;", "SQL")
          adapter.drop_function("add_em", "integer, integer")

          expect(adapter.functions.map(&:name)).not_to include("add_em")
        end

        it "only drops a function that has the exact same signature" do
          adapter = Postgres.new

          adapter.create_function("add_em", "integer, integer", "integer", "SELECT $1 + $2;", "SQL")
          adapter.create_function("add_em", "float, float", "float", "SELECT $1 + $2;", "SQL")
          adapter.drop_function("add_em", "integer, integer")

          expect(adapter.functions.select{|x| x.name == "add_em"}.map(&:arguments)).to eql ["double precision, double precision"]
        end

        it "raises an error if there is no matching function with that name" do
          adapter = Postgres.new
          expect{
            adapter.drop_function("not_here", "integer, integer")
          }.to raise_error(ActiveRecord::StatementInvalid, %r{PG::UndefinedFunction: ERROR:  function not_here\(integer, integer\) does not exist})
        end

        it "raises an error if there is no matching function with that exact signature" do
          adapter = Postgres.new
          adapter.create_function("add_em", "integer, integer", "integer", "SELECT $1 + $2;", "SQL")

          expect{
            adapter.drop_function("add_em", "")
          }.to raise_error(ActiveRecord::StatementInvalid, %r{PG::UndefinedFunction: ERROR:  function add_em\(\) does not exist})
        end
      end

      describe "#drop_aggregate" do
        it "successfully drops an aggregate" do
          adapter = Postgres.new

          adapter.create_aggregate(
            "custom_function",
            "int",
            "sfunc = int4pl,
             stype = int,
             initcond = 10"
          )

          adapter.drop_aggregate("custom_function", "integer")

          expect(adapter.functions.map(&:name)).not_to include("custom_function")
        end

        it "only drops an aggregate that has the exact same signature" do
          adapter = Postgres.new

          adapter.create_aggregate(
            "custom_function",
            "float8",
            "sfunc = float8_accum,
             stype = float8[],
             finalfunc = float8_avg,
             initcond = '{0,0,0}'"
          )

          adapter.create_aggregate(
            "custom_function",
            "int",
            "sfunc = int4pl,
             stype = int,
             initcond = 10"
          )

          adapter.drop_aggregate("custom_function", "integer")

          expect(adapter.functions.select{|x| x.name == "custom_function"}.map(&:arguments)).to eql ["double precision"]
        end

        it "raises an error if there is no matching aggregate with that name" do
          adapter = Postgres.new
          expect{
            adapter.drop_aggregate("not_here", "integer, integer")
          }.to raise_error(ActiveRecord::StatementInvalid, %r{PG::UndefinedFunction: ERROR:  aggregate not_here\(integer, integer\) does not exist})
        end

        it "raises an error if there is no matching aggregate with that exact signature" do
          adapter = Postgres.new
          adapter.create_aggregate(
            "custom_function",
            "float8",
            "sfunc = float8_accum,
             stype = float8[],
             finalfunc = float8_avg,
             initcond = '{0,0,0}'"
          )

          expect{
            adapter.drop_aggregate("custom_function", "integer")
          }.to raise_error(ActiveRecord::StatementInvalid, %r{PG::UndefinedFunction: ERROR:  aggregate custom_function\(integer\) does not exist})
        end
      end

      describe "#functions" do
        it "returns the functions defined on this connection" do
          adapter = Postgres.new

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE FUNCTION add_em(integer, integer) RETURNS integer AS $$ SELECT $1 + $2; $$ LANGUAGE SQL;
          SQL

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE FUNCTION dup(int) RETURNS TABLE(f1 int, f2 text)
              AS $$ SELECT $1, CAST($1 AS text) || ' is text' $$
              LANGUAGE SQL;
          SQL

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE AGGREGATE "custom_function"(int)(
              sfunc = int4pl, stype = int,initcond = 10
            )
          SQL

          expect(adapter.functions.map(&:name).to_set).to eq [
            "add_em",
            "dup",
            "custom_function"
          ].to_set
        end

        context "with views in non public schemas" do
          it "returns also the non public views" do
            adapter = Postgres.new

            ActiveRecord::Base.connection.execute <<-SQL
              CREATE FUNCTION add_em(integer, integer) RETURNS integer AS $$ SELECT $1 + $2; $$ LANGUAGE SQL;
            SQL

            ActiveRecord::Base.connection.execute <<-SQL
              CREATE SCHEMA versioned_database_functions;
              CREATE AGGREGATE versioned_database_functions."custom_function"(int)(
                sfunc = int4pl, stype = int,initcond = 10
              );
              SET search_path TO versioned_database_functions, public;
            SQL

            expect(adapter.functions.map(&:name).to_set).to eq [
              "add_em",
              "versioned_database_functions.custom_function",
            ].to_set
          end
        end
      end
    end
  end
end
