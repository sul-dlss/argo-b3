# frozen_string_literal: true

module CocinaModels
  # Concern for handling embargo in Cocina models.
  module EmbargoConcern
    extend ActiveSupport::Concern

    included do
      attribute :embargo_release_date, :datetime
      attribute :embargo_view, :string
      attribute :embargo_download, :string
      attribute :embargo_location, :string
      # Note that the error is reported on :embargo_access, not the individual embargo fields
      validate :validate_embargo_access, if: :embargo_release_date?
    end

    def embargo_dark_access?
      AccessRightsSupport.dark?(**embargo_access_rights)
    end

    def embargo_citation_only_access?
      AccessRightsSupport.citation_only?(**embargo_access_rights)
    end

    def embargo_location_based_access?
      AccessRightsSupport.location_based?(**embargo_access_rights)
    end

    def embargo_location_based_download_access?
      AccessRightsSupport.location_based_download?(**embargo_access_rights)
    end

    def embargo_stanford_access?
      AccessRightsSupport.stanford?(**embargo_access_rights)
    end

    def embargo_world_access?
      AccessRightsSupport.world?(**embargo_access_rights)
    end

    def embargo_release_date?
      embargo_release_date.present?
    end

    private

    def validate_embargo_access
      return if AccessRightsSupport.valid?(**embargo_access_rights)

      errors.add(:embargo_access, 'is not valid')
    end

    def embargo_access_rights
      { view: embargo_view, download: embargo_download, location: embargo_location }
    end
  end
end
