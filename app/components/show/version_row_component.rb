# frozen_string_literal: true

module Show
  # Renders a version in the versions table.
  class VersionRowComponent < ApplicationComponent
    # @param version [VersionsPresenter::Version]
    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
    #   Cocina::Models::AdminPolicyWithMetadata] the object, which may omit its file sets
    # @param druid_token [String] the signed druid, which authorizes the download links
    def initialize(version:, cocina_object:, druid_token:)
      @version = version
      @cocina_object = cocina_object
      @druid_token = druid_token
      super()
    end

    attr_reader :cocina_object, :druid_token

    delegate :version, :description, :user_version, :opened_at, :accessioned_at, :purl_url, :cocina?, :withdrawn?,
             to: :@version

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

    def download_links
      [cocina_link, structural_csv_link, descriptive_csv_link].compact
    end

    private

    def path_params
      { object_druid: druid_token, version: }
    end

    def cocina_link
      helpers.link_to_new_tab(cocina_object_version_path(**path_params)) do
        safe_join(['Cocina ', helpers.external_link_icon(aria: { hidden: true })])
      end
    end

    def structural_csv_link
      return unless CocinaSupport.item_or_virtual_object?(cocina_object)

      link_to('Structural metadata', structural_csv_object_version_path(**path_params), data: { turbo: false })
    end

    # Items, virtual objects, and collections.
    def descriptive_csv_link
      return if cocina_object.admin_policy? || CocinaSupport.agreement?(cocina_object)

      link_to('Descriptive metadata', descriptive_csv_object_version_path(**path_params), data: { turbo: false })
    end
  end
end
