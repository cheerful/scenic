module VersionedDatabaseFunctions
  class Configuration
    # The VersionedDatabaseFunctions database adapter instance to use when executing SQL.
    #
    # Defualts to an instance of {Adapters::Postgres}
    # @return VersionedDatabaseFunctions adapter
    attr_accessor :database

    def initialize
      @database = VersionedDatabaseFunctions::Adapters::Postgres.new
    end
  end

  # @return [VersionedDatabaseFunctions::Configuration] VersionedDatabaseFunctions's current configuration
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Set VersionedDatabaseFunctions's configuration
  #
  # @param config [VersionedDatabaseFunctions::Configuration]
  def self.configuration=(config)
    @configuration = config
  end

  # Modify VersionedDatabaseFunctions's current configuration
  #
  # @yieldparam [VersionedDatabaseFunctions::Configuration] config current VersionedDatabaseFunctions config
  # ```
  # VersionedDatabaseFunctions.configure do |config|
  #   config.database = VersionedDatabaseFunctions::Adapters::Postgres.new
  # end
  # ```
  def self.configure
    yield configuration
  end
end
