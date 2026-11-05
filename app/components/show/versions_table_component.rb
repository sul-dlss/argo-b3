# frozen_string_literal: true

module Show
  # Renders the versions table of the object show page.
  class VersionsTableComponent < ApplicationComponent
    # @param versions [Array<VersionsPresenter::Version>]
    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
    #   Cocina::Models::AdminPolicyWithMetadata] the object, which may omit its file sets
    def initialize(versions:, cocina_object:)
      @versions = versions
      @cocina_object = cocina_object
      super()
    end

    attr_reader :versions, :cocina_object

    # Only Items and Virtual Objects have User Versions.
    def user_version_columns?
      CocinaSupport.item_or_virtual_object?(cocina_object)
    end
  end
end
