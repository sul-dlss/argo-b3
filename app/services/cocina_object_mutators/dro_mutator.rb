# frozen_string_literal: true

module CocinaObjectMutators
  # Mapper for merging a CocinaModels::Dro with an existing Cocina::Models::DROWithMetadata.
  class DroMutator < BaseMutator
    private

    def build_new_cocina_props
      super.tap do |new_cocina_props|
        new_cocina_props[:access][:view] = cocina_model.access_view
        new_cocina_props[:access][:download] = cocina_model.access_download
        new_cocina_props[:access][:location] = cocina_model.access_location
      end
    end
  end
end
