require "spec_helper"

module VersionedDatabaseFunctions
  describe Configuration do
    after { restore_default_config }

    it "defaults the database adapter to postgres" do
      expect(VersionedDatabaseFunctions.configuration.database).to be_a Adapters::Postgres
      expect(VersionedDatabaseFunctions.database).to be_a Adapters::Postgres
    end

    it "allows the database adapter to be set" do
      adapter = double("VersionedDatabaseFunctions Adapter")

      VersionedDatabaseFunctions.configure do |config|
        config.database = adapter
      end

      expect(VersionedDatabaseFunctions.configuration.database).to eq adapter
      expect(VersionedDatabaseFunctions.database).to eq adapter
    end

    def restore_default_config
      VersionedDatabaseFunctions.configuration = Configuration.new
    end
  end
end
