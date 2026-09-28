# frozen_string_literal: true

module CocinaModels
  # Concern for handling access in Cocina models.
  module AccessConcern
    extend ActiveSupport::Concern

    included do # rubocop:disable Metrics/BlockLength
      # Access fields
      attribute :use_and_reproduction_statement, :string
      attribute :license, :string
      attribute :copyright, :string
      attribute :access_view, :string
      attribute :access_download, :string
      attribute :access_location, :string
      # Note that the error is reported on :access, not :access_view, :access_download, or :access_location
      validate :validate_access

      def validate_access
        return if AccessRightsSupport.valid?(**access_rights)

        errors.add(:access, 'is not valid')
      end

      def dark_access?
        AccessRightsSupport.dark?(**access_rights)
      end

      def citation_only_access?
        AccessRightsSupport.citation_only?(**access_rights)
      end

      def location_based_access?
        AccessRightsSupport.location_based?(**access_rights)
      end

      def location_based_download_access?
        AccessRightsSupport.location_based_download?(**access_rights)
      end

      def stanford_access?
        AccessRightsSupport.stanford?(**access_rights)
      end

      def world_access?
        AccessRightsSupport.world?(**access_rights)
      end

      private

      def access_rights
        { view: access_view, download: access_download, location: access_location }
      end
    end
  end
end
