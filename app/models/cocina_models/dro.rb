# frozen_string_literal: true

module CocinaModels
  # Model for a Cocina DRO object.
  class Dro < Base
    # @param cocina_object [Cocina::Models::DROWithMetadata] the Cocina object to initialize this model with
    def initialize(cocina_object)
      unless cocina_object.is_a?(Cocina::Models::DROWithMetadata)
        raise ArgumentError, 'Expected a Cocina::Models::DROWithMetadata'
      end

      super
    end

    attribute :source_id, :string
    validates :source_id, presence: true
    validates :source_id, format: { with: /\A.+:.+\z/ }

    # Access fields
    attribute :use_and_reproduction_statement, :string
    attribute :license, :string
    attribute :copyright, :string

    private

    def model_attrs_for(cocina_object)
      CocinaModelMappers::DroMapper.call(cocina_object:)
    end

    def mutated_cocina_object
      CocinaObjectMutators::DroMutator.call(cocina_object: previous_cocina_object, cocina_model: self)
    end
  end
end
