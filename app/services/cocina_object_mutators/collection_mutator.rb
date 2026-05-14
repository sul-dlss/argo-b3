# frozen_string_literal: true

module CocinaObjectMutators
  # Mapper for merging a CocinaModels::Collection with an existing Cocina::Models::CollectionWithMetadata.
  class CollectionMutator < BaseMutator
    private

    def build_new_cocina_props
      super.tap do |new_cocina_props|
        new_cocina_props[:access][:view] = cocina_model.access_view
      end
    end
  end
end
