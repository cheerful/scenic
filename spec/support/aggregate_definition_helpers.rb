module AggregateDefinitionHelpers
  def with_aggregate_definition(name, version, schema)
    definition = VersionedDatabaseFunctions::Definitions::Aggregate.new(name, version)
    FileUtils.mkdir_p(File.dirname(definition.full_path))
    File.open(definition.full_path, "w") { |f| f.write(schema) }
    yield
  ensure
    FileUtils.rm_f(definition.full_path)
  end
end
