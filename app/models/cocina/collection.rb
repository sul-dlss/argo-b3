# frozen_string_literal: true

module Cocina
  # Model for a Cocina Collection object.
  class Collection < Base
    # @param cocina_object [Cocina::Models::CollectionWithMetadata] the Cocina object to initialize this model with
    def initialize(cocina_object)
      unless cocina_object.is_a?(Cocina::Models::CollectionWithMetadata)
        raise ArgumentError, 'Expected a Cocina::Models::CollectionWithMetadata'
      end

      super
    end
  end
end
