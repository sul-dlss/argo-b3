# frozen_string_literal: true

module Show
  # Renders a version in the versions table.
  class VersionRowComponent < ApplicationComponent
    # @param version [VersionsPresenter::Version]
    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
    #   Cocina::Models::AdminPolicyWithMetadata] the object, which may omit its file sets
    # @param druid_token [String] the signed druid, which authorizes the download links
    # @param manage_user_versions [Boolean] true if the user may withdraw and restore user versions
    def initialize(version:, cocina_object:, druid_token:, manage_user_versions:)
      @version = version
      @cocina_object = cocina_object
      @druid_token = druid_token
      @manage_user_versions = manage_user_versions
      super()
    end

    attr_reader :cocina_object, :druid_token

    delegate :version, :description, :user_version, :opened_at, :accessioned_at, :purl_url, :cocina?, :withdrawn?,
             :withdrawable?, :restorable?, to: :@version

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

      helpers.link_to_new_tab(with_version_context('PURL'), purl_url)
    end

    def download_links
      [cocina_link, structural_csv_link, descriptive_csv_link].compact
    end

    private

    def user_version_path_params
      { object_druid: cocina_object.externalIdentifier, user_version: }
    end

    # Disabled when the user cannot manage user versions.
    def user_version_button_component(label, path)
      SdrViewComponents::Elements::ButtonFormComponent.new(link: path, label:, method: :post,
                                                           variant: :'outline-primary', size: :sm,
                                                           disabled: !@manage_user_versions)
    end

    # Names the version, since the links repeat on every row.
    def with_version_context(text)
      helpers.text_with_hidden_context(text, "for version #{version}")
    end

    def path_params
      { object_druid: druid_token, version: }
    end

    def cocina_link
      link_to(with_version_context('Cocina'), cocina_object_version_path(**path_params))
    end

    def structural_csv_link
      return unless CocinaSupport.item_or_virtual_object?(cocina_object)

      link_to(with_version_context('Structural metadata'), structural_csv_object_version_path(**path_params),
              data: { turbo: false })
    end

    # Items, virtual objects, and collections.
    def descriptive_csv_link
      return if cocina_object.admin_policy? || CocinaSupport.agreement?(cocina_object)

      link_to(with_version_context('Descriptive metadata'), descriptive_csv_object_version_path(**path_params),
              data: { turbo: false })
    end
  end
end
