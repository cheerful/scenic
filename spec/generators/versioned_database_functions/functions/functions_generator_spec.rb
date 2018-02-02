require "spec_helper"
require "generators/versioned_database_functions/function/function_generator"

describe VersionedDatabaseFunctions::Generators::FunctionGenerator, :generator do
  it "creates function definition and migration files" do
    migration = file("db/migrate/create_running_total.rb")
    function_definition = file("db/functions/running_total_v01.sql")

    run_generator ["running_total", "--arguments='integer, integer'", "--returns='integer'"]

    expect(migration).to be_a_migration
    expect(function_definition).to exist
  end

  it "updates an existing function" do
    with_function_definition("running_total", 1, "SELECT $1 + $2") do
      migration = file("db/migrate/update_running_total_to_version_2.rb")
      function_definition = file("db/functions/running_total_v02.sql")
      allow(Dir).to receive(:entries).and_return(["running_total_v01.sql"])

      run_generator ["running_total", "--arguments='integer, integer'", "--returns='integer'"]

      expect(migration).to be_a_migration
      expect(function_definition).to exist
    end
  end

  context "for functions created in a schema other than 'public'" do
    it "creates function definition and migration files" do
      migration = file("db/migrate/create_non_public_running_total.rb")
      function_definition = file("db/functions/non_public_running_total_v01.sql")

      run_generator ["non_public.running_total", "--arguments='integer, integer'", "--returns='integer'"]

      expect(migration).to be_a_migration
      expect(function_definition).to exist
    end
  end
end
