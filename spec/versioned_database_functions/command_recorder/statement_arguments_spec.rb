require "spec_helper"

module VersionedDatabaseFunctions::CommandRecorder
  describe StatementArguments do
    describe "#function_or_aggregate" do
      it "is the function_or_aggregate name" do
        raw_args = [:spaceships, { foo: :bar }]
        args = StatementArguments.new(raw_args)

        expect(args.function_or_aggregate).to eq :spaceships
      end
    end

    describe "#revert_to_version" do
      it "is the revert_to_version from the keyword arguments" do
        raw_args = [:spaceships, { revert_to_version: 42 }]
        args = StatementArguments.new(raw_args)

        expect(args.revert_to_version).to eq 42
      end

      it "is nil if the revert_to_version was not supplied" do
        raw_args = [:spaceships, { foo: :bar }]
        args = StatementArguments.new(raw_args)

        expect(args.revert_to_version).to be nil
      end
    end

    describe "#arguments" do
      it "is the arguments from the keyword arguments" do
        raw_args = [:spaceships, { arguments: 'integer, integer' }]
        args = StatementArguments.new(raw_args)

        expect(args.arguments).to eq 'integer, integer'
      end

      it "is nil if the arguments was not supplied" do
        raw_args = [:spaceships, { foo: :bar }]
        args = StatementArguments.new(raw_args)

        expect(args.arguments).to be nil
      end
    end

    describe "#returns" do
      it "is the returns from the keyword arguments" do
        raw_args = [:spaceships, { returns: 'integer' }]
        args = StatementArguments.new(raw_args)

        expect(args.returns).to eq 'integer'
      end

      it "is nil if the returns was not supplied" do
        raw_args = [:spaceships, { foo: :bar }]
        args = StatementArguments.new(raw_args)

        expect(args.returns).to be nil
      end
    end

    describe "#invert_version" do
      it "returns object with version set to revert_to_version" do
        raw_args = [:meatballs, { arguments: 'integer, integer', returns: 'integer', version: 42, revert_to_version: 15 }]

        inverted_args = StatementArguments.new(raw_args).invert_version

        expect(inverted_args.version).to eq 15
        expect(inverted_args.arguments).to eq 'integer, integer'
        expect(inverted_args.returns).to eq 'integer'
        expect(inverted_args.revert_to_version).to be nil
      end
    end
  end
end
