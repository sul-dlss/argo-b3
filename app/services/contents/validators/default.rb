# frozen_string_literal: true

module Contents
  module Validators
    # Default validator for Content, which validates nothing.
    # This is also a base class for other validators, which may override the call method to perform validation.
    class Default
      def self.call(...)
        new(...).call
      end

      # @param [Content] content
      # @param [Boolean] dark true if the object is dark
      def initialize(content:, dark:)
        @content = content
        @dark = dark
      end

      # @return [Contents::Validators::Result]
      def call
        result
      end

      private

      attr_reader :content

      def dark?
        @dark
      end

      def result
        @result ||= Result.new
      end

      delegate :errors, :warnings, to: :result
    end
  end
end
