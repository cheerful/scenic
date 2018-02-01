require "spec_helper"

describe VersionedDatabaseFunctions::CommandRecorder do
  describe "#to_schema" do
    it "prepares a database function for schema dumping" do
      function = VersionedDatabaseFunctions::Function.new(
        name: "sum", arguments: "integer, integer", result_data_type: "integer",
        source_code: "SELECT $1 + $2", language: "sql", kind: "normal"
      )

      schema_dump = <<-DEFINITION
  create_function "sum", arguments: "integer, integer", returns: "integer", language: "sql", sql_definition: <<-\SQL
      SELECT $1 + $2
  SQL
      DEFINITION

      expect(function.to_schema).to eq schema_dump
    end
  end
end