# frozen_string_literal: true

module Contents
  module Validators
    # The result of validating the structure of a Content.
    # Errors make the Content invalid; warnings are shared with the user but do not.
    Result = Struct.new(:errors, :warnings) do
      def initialize(errors: [], warnings: [])
        super
      end

      def valid?
        errors.empty?
      end
    end
  end
end
