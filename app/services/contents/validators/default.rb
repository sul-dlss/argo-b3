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

      def content_file_sets
        @content_file_sets ||= content.content_file_sets.includes(content_files: :content_file_binary).to_a
      end

      # Violations are only warnings for a dark object, since none of its files are expected to be published.
      def add_warning_or_error(message)
        (dark? ? warnings : errors) << message
      end

      # @param [Integer] index the 1-based position of the Resource among all of the Resources
      # @return [String] the name of the Resource for messages, e.g., Resource 3 (Page 3)
      def resource_name_for(content_file_set:, index:)
        return "Resource #{index}" if content_file_set.label.blank?

        "Resource #{index} (#{content_file_set.label})"
      end
    end
  end
end
