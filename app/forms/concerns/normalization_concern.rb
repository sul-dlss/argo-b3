# frozen_string_literal: true

# Concern providing helpers for normalizing model attributes.
module NormalizationConcern
  extend ActiveSupport::Concern

  class_methods do
    # Blanks stores normalizations in a class_attribute whose default is a single shared hash that
    # Blanks::Normalization#normalizes mutates in place, so declaring a normalization for an
    # attribute name (e.g., :tag) in one class would clobber it for every other class. Giving the
    # declaring class its own copy first keeps normalizations per-class.
    def normalizes(*, **)
      self._normalizations = _normalizations.dup
      super
    end

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
