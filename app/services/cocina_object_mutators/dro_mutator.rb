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

        update_embargo(new_cocina_props[:access])
      end
    end

    def update_embargo(access_hash)
      if cocina_model.embargo_release_date.blank?
        access_hash.delete(:embargo)
      else
        access_hash[:embargo] = {
          releaseDate: cocina_model.embargo_release_date,
          view: cocina_model.embargo_view,
          download: cocina_model.embargo_download,
          location: cocina_model.embargo_location
        }.compact
      end
    end
  end
end
