require "spec_helper"

module VersionedDatabaseFunctions::Definitions
  describe Function do
    describe "to_sql" do
      it "returns the content of a function definition" do
        sql_definition = "SELECT $1 + $2;"
        allow(File).to receive(:read).and_return(sql_definition)

        definition = Function.new("moving_average", 1)

        expect(definition.to_sql).to eq sql_definition
      end

      it "raises an error if the file is empty" do
        allow(File).to receive(:read).and_return("")

        expect do
          Function.new("moving_average", 1).to_sql
        end.to raise_error RuntimeError
      end
    end

    describe "path" do
      it "returns a sql file in db/functions with padded version and function name"  do
        expected = "db/functions/moving_average_v01.sql"

        definition = Function.new("moving_average", 1)

        expect(definition.path).to eq expected
      end
    end

    describe "full_path" do
      it "joins the path with Rails.root" do
        definition = Function.new("moving_average", 15)

        expect(definition.full_path).to eq Rails.root.join(definition.path)
      end
    end

    describe "version" do
      it "pads the version number with 0" do
        definition = Function.new(:_, 1)

        expect(definition.version).to eq "01"
      end

      it "doesn't pad more than 2 characters" do
        definition = Function.new(:_, 15)

        expect(definition.version).to eq "15"
      end
    end
  end
end
