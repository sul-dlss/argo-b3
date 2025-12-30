# frozen_string_literal: true

# Methods for working with cocina objects
class CocinaSupport
  extend Dry::Monads[:result]

  # Validates a cocina model instance
  # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
  # @param [Hash] params the changed model parameters
  # @return [Dry::Monads::Success] if validation passes
  # @return [Dry::Monads::Failure] if validation fails
  def self.validate(cocina_object, **params)
    Cocina::Models.build(cocina_object.to_h.merge(**params))
    Success()
  rescue Cocina::Models::Error => e
    Failure(e.message)
  end
end
