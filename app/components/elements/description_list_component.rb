# frozen_string_literal: true

module Elements
  # Component for rendering a hash as a description list, with nested hashes rendered as nested description lists.
  # Implements https://getbootstrap.com/docs/5.3/content/typography/#description-list-alignment
  class DescriptionListComponent < ApplicationComponent
    # @param hash [Hash] the hash to render
    # @param nested [Boolean] true if this list is nested in another description list
    def initialize(hash:, nested: false)
      @hash = hash
      @nested = nested
      super()
    end

    # nil and empty values are omitted.
    def entries
      @hash.reject { |_key, value| value.nil? || (value.respond_to?(:empty?) && value.empty?) }
    end

    def term_label(key)
      key.to_s.humanize
    end

    # @return [Array] the value, with arrays rendered as one item per element
    def values_for(value)
      value.is_a?(Array) ? value : [value]
    end

    # Terms are narrower on larger screens, where the full width leaves a large gap before the description.
    def term_classes
      @nested ? 'col-sm-4 col-lg-2' : 'col-sm-3 col-lg-2'
    end

    def description_classes
      @nested ? 'col-sm-8 col-lg-10' : 'col-sm-9 col-lg-10'
    end
  end
end
