module VersionedDatabaseFunctions
  # The in-memory representation of a function source_code.
  #
  # **This object is used internally by adapters and the schema dumper and is
  # not intended to be used by application code. It is documented here for
  # use by adapter gems.**
  #
  # @api extension
  class Function
    # The name of the function
    # @return [String]
    attr_reader :name

    # The SQL schema for the query that defines the function
    # @return [String]
    #
    # @example
    #   "add_em(integer, integer) RETURNS integer AS $$
    #     SELECT $1 + $2;
    #   $$ LANGUAGE SQL;"
    attr_reader :source_code

    # The function's kind
    # @return [String]
    #
    # @example
    #  "aggregate"
    attr_reader :kind

    # The function's kind
    # @return [String]
    #
    # @example
    #  "aggregate"
    attr_reader :language

    # The function's arguments
    # @return [String]
    #
    # @example
    #  "integer, integer"
    attr_reader :arguments

    # The function's result data type
    # @return [String]
    #
    # @example
    #  "integer[]"
    attr_reader :result_data_type

    # Returns a new instance of Function.
    #
    # @param name [String] The name of the function.
    # @param source_code [String] The SQL for the query that defines the function.
    # @param kind [String] The type of function it is.
    def initialize(name:, kind:, source_code:, language:, arguments:,result_data_type:)
      @name = name
      @kind = normalized_kind(kind)
      @source_code = source_code
      @language = language
      @arguments = arguments
      @result_data_type = result_data_type
    end

    # @api private
    def ==(other)
      name == other.name &&
        source_code == other.source_code &&
        kind == other.kind
    end

    # @api private
    def to_schema
      options = "arguments: #{arguments.inspect}, returns: #{result_data_type.inspect}, language: #{language.inspect}"

      <<-DEFINITION
  create_function #{name.inspect}, #{options}, sql_definition: <<-\SQL
    #{source_code.indent(2)}
  SQL
      DEFINITION
    end

    protected

    def normalized_kind(kind)
      kind.strip.downcase
    end
  end
end
