require "spec_helper"

describe VersionedDatabaseFunctions::CommandRecorder do
  describe "#to_schema" do
    it "prepares a database aggregate for schema dumping" do
      allow(VersionedDatabaseFunctions::Definitions::Aggregate).to receive(:latest_version).with("moving_average").and_return(12)

      aggregate = VersionedDatabaseFunctions::Aggregate.new(
        name: "moving_average", arguments: "integer", kind: "aggregate",
        language: "internal", source_code: "aggregate_dummy"
      )

      schema_dump = <<-DEFINITION
  create_aggregate "moving_average", arguments: "integer", version: 12
      DEFINITION

      expect(aggregate.to_schema).to eq schema_dump
    end
  end
end