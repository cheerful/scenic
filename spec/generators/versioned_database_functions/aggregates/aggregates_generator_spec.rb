require "spec_helper"
require "generators/versioned_database_functions/aggregate/aggregate_generator"

describe VersionedDatabaseFunctions::Generators::AggregateGenerator, :generator do
  it "creates aggregate definition and migration files" do
    migration = file("db/migrate/create_moving_average.rb")
    aggregate_definition = file("db/aggregates/moving_average_v01.sql")

    run_generator ["moving_average", "--arguments='float8'"]
    expect(migration).to be_a_migration
    expect(aggregate_definition).to exist
  end

  it "updates an existing aggregate" do
    with_aggregate_definition("moving_average", 1, "hello") do
      migration = file("db/migrate/update_moving_average_to_version_2.rb")
      aggregate_definition = file("db/aggregates/moving_average_v02.sql")
      allow(Dir).to receive(:entries).and_return(["moving_average_v01.sql"])

      run_generator ["moving_average", "--arguments='float8'"]

      expect(migration).to be_a_migration
      expect(aggregate_definition).to exist
    end
  end

  context "for aggregates created in a schema other than 'public'" do
    it "creates aggregate definition and migration files" do
      migration = file("db/migrate/create_non_public_moving_average.rb")
      aggregate_definition = file("db/aggregates/non_public_moving_average_v01.sql")

      run_generator ["non_public.moving_average", "--arguments='float8'"]

      expect(migration).to be_a_migration
      expect(aggregate_definition).to exist
    end
  end
end
