# frozen_string_literal: true

# Concern providing helpers for normalizing model attributes.
module NormalizationConcern
  extend ActiveSupport::Concern

  class_methods do
    # Strips whitespace from the given attributes and normalizes blank values to nil.
    # @param names [Array<Symbol>] the attributes to normalize
    def normalizes_whitespace(*names)
      names.each do |name|
        normalizes name, with: ->(value) { value.strip.presence }
      end
    end

    # Removes blank entries (e.g., a blank option submitted from a select field) from array attributes.
    # @param names [Array<Symbol>] the attributes to normalize
    def normalizes_array_compact_blank(*names)
      names.each do |name|
        normalizes name, with: ->(value) { Array(value).compact_blank }
      end
    end
  end
end
