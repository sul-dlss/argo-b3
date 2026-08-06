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
  end
end
