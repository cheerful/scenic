module VersionedDatabaseFunctions
  # The in-memory representation of a aggregate source_code.
  #
  # **This object is used internally by adapters and the schema dumper and is
  # not intended to be used by application code. It is documented here for
  # use by adapter gems.**
  #
  # @api extension
  class Aggregate
    # The name of the aggregate
    # @return [String]
    attr_reader :name

    # The SQL schema for the query that defines the aggregate
    # @return [String]
    #
    # @example
    #   "add_em(integer, integer) RETURNS integer AS $$
    #     SELECT $1 + $2;
    #   $$ LANGUAGE SQL;"
    attr_reader :source_code

    # The aggregate's kind
    # @return [String]
    #
    # @example
    #  "aggregate"
    attr_reader :kind

    # The aggregate's kind
    # @return [String]
    #
    # @example
    #  "aggregate"
    attr_reader :language

    # The aggregate's arguments
    # @return [String]
    #
    # @example
    #  "integer, integer"
    attr_reader :arguments

    # Returns a new instance of Function.
    #
    # @param name [String] The name of the aggregate.
    # @param source_code [String] The SQL for the query that defines the aggregate.
    # @param kind [String] The type of aggregate it is.
    def initialize(name:, kind:, source_code:, language:, arguments:)
      @name = name
      @kind = normalized_kind(kind)
      @source_code = source_code
      @language = language
      @arguments = arguments
    end

    # @api private
    def ==(other)
      name == other.name &&
        arguments == other.arguments &&
        language == other.language &&
        source_code == other.source_code &&
        kind == other.kind
    end

    # @api private
    def to_schema
      options = "arguments: #{arguments.inspect}, version: #{latest_version}"
      "create_aggregate #{name.inspect}, #{options}"
    end

    protected

    def latest_version
      Definitions::Aggregate.latest_version(name)
    end

    def normalized_kind(kind)
      kind.strip.downcase
    end
  end
end
