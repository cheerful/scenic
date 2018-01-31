require "spec_helper"

module VersionedDatabaseFunctions
  describe VersionedDatabaseFunctions::Statements do
    before do
      adapter = instance_double("VersionedDatabaseFunctions::Adapaters::Postgres").as_null_object
      allow(VersionedDatabaseFunctions).to receive(:database).and_return(adapter)
    end

    describe "create_function" do
      it "creates a function from a file" do
        version = 15
        definition_stub = instance_double("Function", to_sql: "foo")
        allow(Definitions::Function).to receive(:new)
          .with(:sum, version)
          .and_return(definition_stub)

        connection.create_function :sum, arguments: "integer, integer", returns: "integer", version: version

        expect(VersionedDatabaseFunctions.database).to have_received(:create_function)
          .with(:sum, "integer, integer", "integer", "foo", :sql)
      end

      it "creates a function from a text definition" do
        sql_definition = "a defintion"

        connection.create_function(:sum, arguments: "integer, integer", returns: "integer", sql_definition: sql_definition)

        expect(VersionedDatabaseFunctions.database).to have_received(:create_function)
          .with(:sum, "integer, integer", "integer", "a defintion", :sql)
      end

      it "creates version 1 of the function if neither version nor sql_defintion are provided" do
        version = 1
        definition_stub = instance_double("Function", to_sql: "foo")
        allow(Definitions::Function).to receive(:new)
          .with(:sum, version)
          .and_return(definition_stub)

        connection.create_function :sum, arguments: "integer, integer", returns: "integer"

        expect(VersionedDatabaseFunctions.database).to have_received(:create_function)
          .with(:sum, "integer, integer", "integer", "foo", :sql)
      end

      it "raises an error if both version and sql_defintion are provided" do
        expect do
          connection.create_function :sum, arguments: "integer, integer", returns: "integer", version: 10, sql_definition: "hello;"
        end.to raise_error ArgumentError
      end
    end

    describe "drop_function" do
      it "removes a function from the database" do
        connection.drop_function :sum, arguments: "integer, integer"

        expect(VersionedDatabaseFunctions.database).to have_received(:drop_function).with(:sum, "integer, integer")
      end
    end

    describe "update_function" do
      it "updates the function in the database" do
        definition_stub = instance_double("Function", to_sql: "foo")
        allow(Definitions::Function).to receive(:new)
          .with(:sum, 3)
          .and_return(definition_stub)

        connection.update_function(:sum, arguments: "integer, integer", returns: "integer", version: 3)

        expect(VersionedDatabaseFunctions.database).to have_received(:update_function)
          .with(:sum, "integer, integer", "integer", "foo", :sql)
      end

      it "updates a function from a text definition" do
        sql_definition = "a defintion"

        connection.update_function(:sum, arguments: "integer, integer", returns: "integer", sql_definition: sql_definition)

        expect(VersionedDatabaseFunctions.database).to have_received(:update_function)
          .with(:sum, "integer, integer", "integer", "a defintion", :sql)
      end

      it "raises an error if not supplied a version or sql_defintion" do
        expect { connection.update_function :sum, arguments: "integer, integer", returns: "integer" }.to raise_error(
          ArgumentError,
          /sql_definition or version must be specified/)
      end

      it "raises an error if both version and sql_defintion are provided" do
        expect do
          connection.update_function(
            :sum, arguments: "integer, integer", returns: "integer",
            version: 1,
            sql_definition: "a defintion")
        end.to raise_error ArgumentError, /cannot both be set/
      end
    end

    describe "replace_function" do
      it "replaces the function in the database" do
        definition_stub = instance_double("Function", to_sql: "foo")
        allow(Definitions::Function).to receive(:new)
          .with(:sum, 3)
          .and_return(definition_stub)

        connection.replace_function(:sum, arguments: "integer, integer", returns: "integer", version: 3)

        expect(VersionedDatabaseFunctions.database).to have_received(:replace_function)
          .with(:sum, "integer, integer", "integer", "foo", :sql)
      end

      it "raises an error if not supplied a version" do
        expect { connection.replace_function :sum, arguments: "integer, integer", returns: "integer" }
          .to raise_error(ArgumentError, /version is required/)
      end
    end

        describe "create_aggregate" do
      it "creates an aggreate from a file" do
        version = 15
        definition_stub = instance_double("Aggregate", to_sql: "foo")
        allow(Definitions::Aggregate).to receive(:new)
          .with(:sum, version)
          .and_return(definition_stub)

        connection.create_aggregate :sum, arguments: "integer, integer", version: version

        expect(VersionedDatabaseFunctions.database).to have_received(:create_aggregate)
          .with(:sum, "integer, integer", "foo")
      end

      it "creates an aggreate from a text definition" do
        sql_definition = "a defintion"

        connection.create_aggregate(:sum, arguments: "integer, integer", sql_definition: sql_definition)

        expect(VersionedDatabaseFunctions.database).to have_received(:create_aggregate)
          .with(:sum, "integer, integer", "a defintion")
      end

      it "creates version 1 of the aggregate if neither version nor sql_defintion are provided" do
        version = 1
        definition_stub = instance_double("Aggregate", to_sql: "foo")
        allow(Definitions::Aggregate).to receive(:new)
          .with(:sum, version)
          .and_return(definition_stub)

        connection.create_aggregate :sum, arguments: "integer, integer"

        expect(VersionedDatabaseFunctions.database).to have_received(:create_aggregate)
          .with(:sum, "integer, integer", "foo")
      end

      it "raises an error if both version and sql_defintion are provided" do
        expect do
          connection.create_aggregate :sum, arguments: "integer, integer", version: 10, sql_definition: "hello;"
        end.to raise_error ArgumentError
      end
    end

    describe "drop_aggregate" do
      it "removes an aggreate from the database" do
        connection.drop_aggregate :sum, arguments: "integer, integer"

        expect(VersionedDatabaseFunctions.database).to have_received(:drop_aggregate).with(:sum, "integer, integer")
      end
    end

    describe "update_aggregate" do
      it "updates the aggregate in the database" do
        definition_stub = instance_double("Aggregate", to_sql: "foo")
        allow(Definitions::Aggregate).to receive(:new)
          .with(:sum, 3)
          .and_return(definition_stub)

        connection.update_aggregate(:sum, arguments: "integer, integer", version: 3)

        expect(VersionedDatabaseFunctions.database).to have_received(:update_aggregate)
          .with(:sum, "integer, integer", "foo")
      end

      it "updates an aggreate from a text definition" do
        sql_definition = "a defintion"

        connection.update_aggregate(:sum, arguments: "integer, integer", sql_definition: sql_definition)

        expect(VersionedDatabaseFunctions.database).to have_received(:update_aggregate)
          .with(:sum, "integer, integer", "a defintion")
      end

      it "raises an error if not supplied a version or sql_defintion" do
        expect { connection.update_aggregate :sum, arguments: "integer, integer" }.to raise_error(
          ArgumentError,
          /sql_definition or version must be specified/)
      end

      it "raises an error if both version and sql_defintion are provided" do
        expect do
          connection.update_aggregate(
            :sum, arguments: "integer, integer",
            version: 1,
            sql_definition: "a defintion")
        end.to raise_error ArgumentError, /cannot both be set/
      end
    end

    def connection
      Class.new { extend Statements }
    end
  end
end
