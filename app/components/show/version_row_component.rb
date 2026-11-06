# frozen_string_literal: true

module Show
  # Renders a version in the versions table.
  class VersionRowComponent < ApplicationComponent
    # @param version [VersionsPresenter::Version]
    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
    #   Cocina::Models::AdminPolicyWithMetadata] the object, which may omit its file sets
    def initialize(version:, cocina_object:)
      @version = version
      @cocina_object = cocina_object
      super()
    end

    attr_reader :cocina_object

    delegate :version, :description, :user_version, :opened_at, :accessioned_at, :purl_url, :withdrawn?, to: :@version

    # Only Items and Virtual Objects have User Versions.
    def user_version_columns?
      CocinaSupport.item_or_virtual_object?(cocina_object)
    end

    def user_version_label
      return if user_version.blank?
      return "#{user_version} (withdrawn)" if withdrawn?

      user_version.to_s
    end

    def purl_link
      return if purl_url.blank?

      helpers.link_to_new_tab('PURL', purl_url)
    end
  end
end
