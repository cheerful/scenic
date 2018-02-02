require "spec_helper"

describe "Reverting versioned_database_functions schema statements", :db, :functions do
  around do |example|
    with_function_definition("custom_sum", 1, "SELECT $1 + $2;") do
      example.run
    end
  end

  it "reverts dropped function to specified version" do
    run_migration(migration_for_create, :up)
    run_migration(migration_for_drop, :up)
    run_migration(migration_for_drop, :down)

    expect { execute("SELECT custom_sum(1,2)") }
      .not_to raise_error
  end

  it "reverts updated view to specified version" do
    with_function_definition :custom_sum, 2, "SELECT ($1 + $2 + 3);" do
      run_migration(migration_for_create, :up)
      run_migration(migration_for_update, :up)
      run_migration(migration_for_update, :down)

      result = execute("SELECT custom_sum(1,2)")[0]["custom_sum"]

      expect(result.to_s).to eq "3"
    end
  end

  def migration_for_create
    Class.new(migration_class) do
      def change
        create_function :custom_sum, arguments: 'integer, integer', returns: 'integer'
      end
    end
  end

  def migration_for_drop
    Class.new(migration_class) do
      def change
        drop_function :custom_sum, arguments: 'integer, integer', returns: 'integer', revert_to_version: 1
      end
    end
  end

  def migration_for_update
    Class.new(migration_class) do
      def change
        update_function :custom_sum, arguments: 'integer, integer', returns: 'integer', version: 2, revert_to_version: 1
      end
    end
  end

  def migration_class
    if Rails::VERSION::MAJOR >= 5
      ::ActiveRecord::Migration[5.0]
    else
      ::ActiveRecord::Migration
    end
  end

  def run_migration(migration, directions)
    silence_stream(STDOUT) do
      Array.wrap(directions).each do |direction|
        migration.migrate(direction)
      end
    end
  end

  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
end

describe "Reverting versioned_database_functions schema statements", :db, :aggregates do
  around do |example|
    sql_definition = "sfunc = float8_accum, stype = float8[], finalfunc = float8_avg, initcond = '{0,0,0}'"
    with_aggregate_definition("custom_average", 1, sql_definition) do
      example.run
    end
  end

  it "reverts dropped aggregate to specified version" do
    run_migration(migration_for_create, :up)
    run_migration(migration_for_drop, :up)
    run_migration(migration_for_drop, :down)

    expect { execute("SELECT custom_average(num) FROM (VALUES (1.0), (2.0), (3.0)) AS x(num);") }
      .not_to raise_error
  end

  it "reverts updated view to specified version" do
    with_aggregate_definition :custom_average, 2, "sfunc = float8_accum, stype = float8[], finalfunc = float8_avg, initcond = '{1,2,3}'" do
      run_migration(migration_for_create, :up)
      run_migration(migration_for_update, :up)
      run_migration(migration_for_update, :down)

      result = execute("SELECT custom_average(num) FROM (VALUES (1.0), (2.0), (3.0)) AS x(num);")[0]["custom_average"]

      expect(result.to_s).to eq "2"
    end
  end

  def migration_for_create
    Class.new(migration_class) do
      def change
        create_aggregate :custom_average, arguments: 'float8'
      end
    end
  end

  def migration_for_drop
    Class.new(migration_class) do
      def change
        drop_aggregate :custom_average, arguments: 'float8', revert_to_version: 1
      end
    end
  end

  def migration_for_update
    Class.new(migration_class) do
      def change
        update_aggregate :custom_average, arguments: 'float8', version: 2, revert_to_version: 1
      end
    end
  end

  def migration_class
    if Rails::VERSION::MAJOR >= 5
      ::ActiveRecord::Migration[5.0]
    else
      ::ActiveRecord::Migration
    end
  end

  def run_migration(migration, directions)
    silence_stream(STDOUT) do
      Array.wrap(directions).each do |direction|
        migration.migrate(direction)
      end
    end
  end

  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
end