# frozen_string_literal: true

module Search
  # Form for a basic search
  class Form < ApplicationForm
    attribute :query, :string
    attribute :include_google_books, :boolean, default: false
    attribute :page, :integer, default: 1
    attribute :debug, :boolean, default: false

    def blank?
      attributes.except('include_google_books', 'page', 'debug').values.all?(&:blank?)
    end

    # @return [hash] this form's attributes merged with new_attrs
    # new_attrs take precedence for scalar values; arrays are merged_attrs
    def with_attributes(new_attrs) # rubocop:disable Metrics/AbcSize
      attributes.with_indifferent_access.tap do |merged_attrs|
        new_attrs.each do |key, value|
          if merged_attrs[key].is_a?(Array)
            if value.is_a?(Array)
              merged_attrs[key] = (merged_attrs[key] + value).uniq
            else
              merged_attrs[key] << value unless merged_attrs[key].include?(value) || value.nil?
            end
          else
            merged_attrs[key] = value
          end
        end
      end
    end

    # @return [hash] this form's attributes with provided attrs removed
    def without_attributes(without_attrs)
      attributes.with_indifferent_access.tap do |new_attrs|
        without_attrs.each do |key, value|
          if new_attrs[key].is_a?(Array) && value.present?
            new_attrs[key] = new_attrs[key] - Array(value)
          elsif new_attrs[key] == value || value.nil?
            new_attrs[key] = nil
          end
        end
      end.compact
    end

    # @return [boolean] whether the given key/value is selected in this form
    def selected?(key:, value:)
      attrs = attributes.with_indifferent_access
      if attrs[key].is_a?(Array)
        attrs[key].include?(value)
      else
        attrs[key] == value
      end
    end

    def attributes
      # This drops attributes with false values so that they are not included in URLs.
      super.compact_blank
    end

    # @return [Hash] attributes defined on this class (not its superclasses)
    def this_attributes
      # To be overridden in subclasses
      []
    end
  end
end
