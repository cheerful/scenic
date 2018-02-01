require "spec_helper"

module VersionedDatabaseFunctions::Definitions
  describe Aggregate do
    describe "to_sql" do
      it "returns the content of a aggregate definition" do
        sql_definition = "sfunc = int4pl, stype = int, initcond = 10"
        allow(File).to receive(:read).and_return(sql_definition)

        definition = Aggregate.new("custom_average", 1)

        expect(definition.to_sql).to eq sql_definition
      end

      it "raises an error if the file is empty" do
        allow(File).to receive(:read).and_return("")

        expect do
          Aggregate.new("custom_average", 1).to_sql
        end.to raise_error RuntimeError
      end
    end

    describe "path" do
      it "returns a sql file in db/aggregates with padded version and aggregate name"  do
        expected = "db/aggregates/custom_average_v01.sql"

        definition = Aggregate.new("custom_average", 1)

        expect(definition.path).to eq expected
      end
    end

    describe "full_path" do
      it "joins the path with Rails.root" do
        definition = Aggregate.new("custom_average", 15)

        expect(definition.full_path).to eq Rails.root.join(definition.path)
      end
    end

    describe "version" do
      it "pads the version number with 0" do
        definition = Aggregate.new(:_, 1)

        expect(definition.version).to eq "01"
      end

      it "doesn't pad more than 2 characters" do
        definition = Aggregate.new(:_, 15)

        expect(definition.version).to eq "15"
      end
    end
  end

  describe "self.latest_version" do
      it "returns the latest version of an aggregate function" do
        definition_files = [
          "db/aggregates/moving_average_v01.sql",
          "db/aggregates/moving_average_v02.sql",
          "db/aggregates/moving_average_v03.sql",
          "db/aggregates/moving_average_v04.sql"
        ]
        allow(Dir).to receive(:glob).and_return(definition_files)

        latest_version = Aggregate.latest_version("moving_average")

        expect(latest_version).to eq 4
      end

      it "raises an error if the file is empty" do
        allow(Dir).to receive(:glob).and_return([])

        expect do
          Aggregate.latest_version("moving_average")
        end.to raise_error RuntimeError
      end
    end
end
