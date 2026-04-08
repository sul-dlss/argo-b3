# frozen_string_literal: true

module CocinaModels
  # Model for a Cocina AdminPolicy object.
  class AdminPolicy < Base
    # @param cocina_object [Cocina::Models::AdminPolicyWithMetadata] the Cocina object to initialize this model with
    def initialize(cocina_object)
      unless cocina_object.is_a?(Cocina::Models::AdminPolicyWithMetadata)
        raise ArgumentError, 'Expected a Cocina::Models::AdminPolicyWithMetadata'
      end

      super
    end

    private

    def model_attrs_for(_cocina_object)
      # Not yet implemented.
      {}
    end
  end
end
