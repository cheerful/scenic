module VersionedDatabaseFunctions
  module Generators
    # @api private
    module Arguments
      extend ActiveSupport::Concern

      included do
        class_option :arguments,
          type: :string,
          required: true,
          desc: "The arguments of the function/aggregate"
      end

      private

      def arguments
        options[:arguments]
      end
    end
  end
end