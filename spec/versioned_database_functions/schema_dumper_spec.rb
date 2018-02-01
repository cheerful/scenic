require "spec_helper"

class Search < ActiveRecord::Base; end

class SearchInAHaystack < ActiveRecord::Base
  self.table_name = '"search in a haystack"'
end

describe VersionedDatabaseFunctions::SchemaDumper, :db, :functions do
  it "dumps a create_function for a function in the database" do
    function_definition = "SELECT $1 + $2;"
    Search.connection.create_function :custom_sum, arguments: 'integer, integer', returns: 'integer', sql_definition: function_definition
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(Search.connection, stream)

    output = stream.string
    expect(output).to include 'create_function "custom_sum"'
    expect(output).to include function_definition

    Search.connection.drop_function :custom_sum, arguments: 'integer, integer'

    silence_stream(STDOUT) { eval(output) }

    expect(Search.connection.execute("SELECT custom_sum(1, 2);")[0]["custom_sum"]).to eq 3
  end

  context "with functions in non public schemas" do
    it "dumps a create_function including namespace for a function in the database" do
      function_definition = "SELECT $1 + $2;"
      Search.connection.execute "CREATE SCHEMA versioned_database_functions; SET search_path TO versioned_database_functions, public"
      Search.connection.create_function "versioned_database_functions.custom_sum", arguments: 'integer, integer', returns: 'integer', sql_definition: function_definition
      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(Search.connection, stream)

      output = stream.string
      expect(output).to include 'create_function "versioned_database_functions.custom_sum",'

      Search.connection.drop_function :'versioned_database_functions.custom_sum', arguments: 'integer, integer'
    end
  end

  it "ignores tables internal to Rails" do
    function_definition = "SELECT $1 + $2;"
    Search.connection.create_function :custom_sum, arguments: 'integer, integer', returns: 'integer', sql_definition: function_definition
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(Search.connection, stream)

    output = stream.string

    expect(output).to include 'create_function "custom_sum"'
    expect(output).not_to include "ar_internal_metadata"
    expect(output).not_to include "schema_migrations"
  end

  context "with functions using unexpected characters in name" do
    it "dumps a create_function for a function in the database" do
      function_definition = "SELECT $1 + $2;"
      Search.connection.create_function '"custom_sum"', arguments: 'integer, integer', returns: 'integer', sql_definition: function_definition
      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(Search.connection, stream)

      output = stream.string
      expect(output).to include 'create_function "custom_sum",'
      expect(output).to include function_definition

      Search.connection.drop_function :'"custom_sum"', arguments: 'integer, integer'

      silence_stream(STDOUT) { eval(output) }

      expect(Search.connection.execute("SELECT custom_sum(1, 2);")[0]["custom_sum"]).to eq 3
    end
  end

  context "with functions using unexpected characters, name including namespace" do
    it "dumps a create_function for a function in the database" do
      function_definition = "SELECT $1 + $2;"
      Search.connection.execute(
        "CREATE SCHEMA versioned_database_functions; SET search_path TO versioned_database_functions, public")
      Search.connection.create_function 'versioned_database_functions."custom_sum"',
        arguments: 'integer, integer', returns: 'integer', sql_definition: function_definition
      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(Search.connection, stream)

      output = stream.string
      expect(output).to include 'create_function "versioned_database_functions.custom_sum",'
      expect(output).to include function_definition

      Search.connection.drop_function :'versioned_database_functions."custom_sum"', arguments: 'integer, integer'

      silence_stream(STDOUT) { eval(output) }

      expect(Search.connection.execute("SELECT custom_sum(1, 2);")[0]["custom_sum"]).to eq 3
    end
  end
end

describe VersionedDatabaseFunctions::SchemaDumper, :db, :aggregates do
  it "dumps a create_aggregate for an aggregate in the database" do
    sql_definition = "sfunc = float8_accum, stype = float8[], finalfunc = float8_avg, initcond = '{0,0,0}'"
    allow(File).to receive(:read).and_return(sql_definition)

    allow(VersionedDatabaseFunctions::Definitions::Aggregate).to receive(:latest_version).with("custom_average").and_return(1)

    Search.connection.create_aggregate :custom_average, arguments: 'float8'
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(Search.connection, stream)

    output = stream.string
    expect(output).to include 'create_aggregate "custom_average", arguments: "double precision", version: 1'

    Search.connection.drop_aggregate :custom_average, arguments: 'float8'

    silence_stream(STDOUT) { eval(output) }

    result = Search.connection.execute("SELECT custom_average(num) FROM (VALUES (1.0), (2.0), (3.0)) AS x(num);")
    expect(result[0]["custom_average"]).to eql 2.0
  end

  context "with aggregates in non public schemas" do
    it "dumps a create_aggregate including namespace for a aggregate in the database" do
      sql_definition = "sfunc = float8_accum, stype = float8[], finalfunc = float8_avg, initcond = '{0,0,0}'"
      allow(File).to receive(:read).and_return(sql_definition)

      allow(VersionedDatabaseFunctions::Definitions::Aggregate).to receive(:latest_version).with("versioned_database_functions.custom_average").and_return(1)

      Search.connection.execute "CREATE SCHEMA versioned_database_functions; SET search_path TO versioned_database_functions, public"
      Search.connection.create_aggregate "versioned_database_functions.custom_average", arguments: 'float8', version: 1
      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(Search.connection, stream)

      output = stream.string
      expect(output).to include 'create_aggregate "versioned_database_functions.custom_average", arguments: "double precision", version: 1'

      Search.connection.drop_aggregate :'versioned_database_functions.custom_average', arguments: 'float8'
    end
  end

  it "ignores tables internal to Rails" do
    sql_definition = "sfunc = float8_accum, stype = float8[], finalfunc = float8_avg, initcond = '{0,0,0}'"
    allow(File).to receive(:read).and_return(sql_definition)

    allow(VersionedDatabaseFunctions::Definitions::Aggregate).to receive(:latest_version).with("custom_average").and_return(1)

    Search.connection.create_aggregate :custom_average, arguments: 'float8'
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(Search.connection, stream)

    output = stream.string

    expect(output).to include 'create_aggregate "custom_average"'
    expect(output).not_to include "ar_internal_metadata"
    expect(output).not_to include "schema_migrations"
  end

  context "with aggregates using unexpected characters in name" do
    it "dumps a create_aggregate for a aggregate in the database" do
      sql_definition = "sfunc = float8_accum, stype = float8[], finalfunc = float8_avg, initcond = '{0,0,0}'"
      allow(File).to receive(:read).and_return(sql_definition)

      allow(VersionedDatabaseFunctions::Definitions::Aggregate).to receive(:latest_version).with("custom_average").and_return(1)

      Search.connection.create_aggregate :"custom_average", arguments: 'float8'
      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(Search.connection, stream)

      output = stream.string
      expect(output).to include 'create_aggregate "custom_average", arguments: "double precision", version: 1'

      Search.connection.drop_aggregate :'"custom_average"', arguments: 'float8'

      silence_stream(STDOUT) { eval(output) }

      result = Search.connection.execute("SELECT custom_average(num) FROM (VALUES (1.0), (2.0), (3.0)) AS x(num);")
      expect(result[0]["custom_average"]).to eql 2.0
    end
  end

  context "with aggregates using unexpected characters, name including namespace" do
    it "dumps a create_aggregate for a aggregate in the database" do
      sql_definition = "sfunc = float8_accum, stype = float8[], finalfunc = float8_avg, initcond = '{0,0,0}'"
      allow(File).to receive(:read).and_return(sql_definition)

      allow(VersionedDatabaseFunctions::Definitions::Aggregate).to receive(:latest_version).with("versioned_database_functions.custom_average").and_return(1)

      Search.connection.execute "CREATE SCHEMA versioned_database_functions; SET search_path TO versioned_database_functions, public"
      Search.connection.create_aggregate 'versioned_database_functions."custom_average"', arguments: 'float8', version: 1
      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(Search.connection, stream)

      output = stream.string
      expect(output).to include 'create_aggregate "versioned_database_functions.custom_average", arguments: "double precision", version: 1'

      Search.connection.drop_aggregate :'versioned_database_functions.custom_average', arguments: 'float8'
    end
  end
end