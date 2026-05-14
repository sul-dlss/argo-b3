# frozen_string_literal: true

module CocinaModels
  # Factory for creating CocinaModels presenters from Cocina models.
  class PresenterFactory
    # @param cocina_model [CocinaModels::Dro, CocinaModels::Collection, CocinaModels::AdminPolicy]
    # @return [CocinaModels::DroPresenter, CocinaModels::CollectionPresenter, CocinaModels::AdminPolicyPresenter]
    def self.build(cocina_model)
      case cocina_model
      when CocinaModels::Dro
        DroPresenter.new(cocina_model)
      when CocinaModels::Collection
        CollectionPresenter.new(cocina_model)
      when CocinaModels::AdminPolicy
        AdminPolicyPresenter.new(cocina_model)
      else
        raise ArgumentError, 'Unexpected cocina object type'
      end
    end

    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
    #   Cocina::Models::AdminPolicyWithMetadata]
    # @return [CocinaModels::DroPresenter, CocinaModels::CollectionPresenter, CocinaModels::AdminPolicyPresenter]
    def self.build_from_cocina_object(cocina_object)
      cocina_model = CocinaModels::Factory.build(cocina_object)
      build(cocina_model)
    end

    # @param cocina_hash [Hash] a hash representing a Cocina model with metadata
    # @return [CocinaModels::DroPresenter, CocinaModels::CollectionPresenter, CocinaModels::AdminPolicyPresenter]
    def self.build_from_cocina_hash(cocina_hash)
      created = cocina_hash.delete(:created)
      modified = cocina_hash.delete(:modified)
      lock = cocina_hash.delete(:lock)
      cocina_object = Cocina::Models.build(cocina_hash, validate: false)
      cocina_object_with_metadata = Cocina::Models.with_metadata(cocina_object, lock, created:, modified:)
      build_from_cocina_object(cocina_object_with_metadata)
    end
  end
end
