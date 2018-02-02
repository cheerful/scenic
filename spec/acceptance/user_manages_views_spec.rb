require "acceptance_helper"

describe "User manages functions" do
  it "handles simple functions" do
    successfully "rails generate versioned_database_functions:function custom_sum --arguments='integer, integer' --returns='integer'"
    write_definition "custom_sum_v01", "SELECT $1 + $2"

    successfully "rake db:migrate"
    verify_result "ActiveRecord::Base.connection.execute('SELECT custom_sum(1, 2);')[0]['custom_sum'].to_i.to_s", "3"

    successfully "rails generate versioned_database_functions:function custom_sum --arguments='integer, integer' --returns='integer'"
    verify_identical_function_definitions "custom_sum_v01", "custom_sum_v02"

    write_definition "custom_sum_v02", "SELECT $1 + $2 + 3"
    successfully "rake db:migrate"

    successfully "rake db:reset"
    verify_result "ActiveRecord::Base.connection.execute('SELECT custom_sum(1, 2);')[0]['custom_sum'].to_i.to_s", "6"

    successfully "rake db:rollback"
    successfully "rake db:rollback"
    successfully "rails destroy versioned_database_functions:function custom_sum --arguments='integer, integer' --returns='integer'"
  end

  it "handles plural function names gracefully during generation" do
    successfully "rails generate versioned_database_functions:function running_totals --arguments='integer, integer' --returns='integer'"
    successfully "rails destroy versioned_database_functions:function running_totals --arguments='integer, integer' --returns='integer'"
  end

  def successfully(command)
    `RAILS_ENV=test #{command}`
    expect($?.exitstatus).to eq(0), "'#{command}' was unsuccessful"
  end

  def write_definition(file, contents)
    File.open("db/functions/#{file}.sql", File::WRONLY) do |definition|
      definition.truncate(0)
      definition.write(contents)
    end
  end

  def verify_result(command, expected_output)
    successfully %{rails runner "puts #{command} == '#{expected_output}' || exit(1)"}
  end

  def verify_identical_function_definitions(def_a, def_b)
    successfully "cmp db/functions/#{def_a}.sql db/functions/#{def_b}.sql"
  end

  def add_index(table, column)
    successfully(<<-CMD.strip)
      rails runner 'ActiveRecord::Migration.add_index "#{table}", "#{column}"'
    CMD
  end

  def verify_schema_contains(statement)
    expect(File.readlines("db/schema.rb").grep(/#{statement}/))
      .not_to be_empty, "Schema does not contain '#{statement}'"
  end
end


describe "User manages aggregates" do
  it "handles simple aggregates" do
    successfully "rails generate versioned_database_functions:aggregate custom_average --arguments='float8'"
    write_definition "custom_average_v01", "sfunc = float8_accum, stype = float8[], finalfunc = float8_avg, initcond = '{0,0,0}'"

    successfully "rake db:migrate"
    verify_result "ActiveRecord::Base.connection.execute('SELECT custom_average(num) FROM (VALUES (1.0), (2.0), (3.0)) AS x(num);')[0]['custom_average'].to_i.to_s", "2"

    successfully "rails generate versioned_database_functions:aggregate custom_average --arguments='float8'"
    verify_identical_function_definitions "custom_average_v01", "custom_average_v02"

    write_definition "custom_average_v02", "sfunc = float8_accum, stype = float8[], finalfunc = float8_avg, initcond = '{2,2,3}'"
    successfully "rake db:migrate"

    successfully "rake db:reset"
    verify_result "ActiveRecord::Base.connection.execute('SELECT custom_average(num) FROM (VALUES (1.0), (2.0), (3.0)) AS x(num);')[0]['custom_average'].to_s", "1.6"

    successfully "rake db:rollback"
    successfully "rake db:rollback"
    successfully "rails destroy versioned_database_functions:aggregate custom_average --arguments='float8'"
  end

  it "handles plural aggregate names gracefully during generation" do
    successfully "rails generate versioned_database_functions:aggregate running_totals --arguments='integer, integer'"
    successfully "rails destroy versioned_database_functions:aggregate running_totals --arguments='integer, integer'"
  end

  def successfully(command)
    `RAILS_ENV=test #{command}`
    expect($?.exitstatus).to eq(0), "'#{command}' was unsuccessful"
  end

  def write_definition(file, contents)
    File.open("db/aggregates/#{file}.sql", File::WRONLY) do |definition|
      definition.truncate(0)
      definition.write(contents)
    end
  end

  def verify_result(command, expected_output)
    successfully %{rails runner "puts #{command} == '#{expected_output}' || exit(1)"}
  end

  def verify_identical_function_definitions(def_a, def_b)
    successfully "cmp db/aggregates/#{def_a}.sql db/aggregates/#{def_b}.sql"
  end

  def add_index(table, column)
    successfully(<<-CMD.strip)
      rails runner 'ActiveRecord::Migration.add_index "#{table}", "#{column}"'
    CMD
  end

  def verify_schema_contains(statement)
    expect(File.readlines("db/schema.rb").grep(/#{statement}/))
      .not_to be_empty, "Schema does not contain '#{statement}'"
  end
end
