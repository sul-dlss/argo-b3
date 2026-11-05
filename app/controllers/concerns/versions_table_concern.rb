# frozen_string_literal: true

# Concern for controllers that render the versions table of the object show page.
# The including controller must include TokenConcern with the 'show' token purpose.
module VersionsTableConcern
  extend ActiveSupport::Concern

  private

  # @param druid [String] the druid of the object
  # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata,
  #   Cocina::Models::AdminPolicyWithMetadata] the object, which may omit its file sets
  # @return [Show::VersionsTableComponent]
  def versions_table_component(druid:, cocina_object:)
    versions_presenter = VersionsPresenter.new(druid:,
                                               version_inventory: Sdr::VersionService.inventory(druid:),
                                               milestones: Sdr::WorkflowService.milestones(druid:),
                                               user_version_inventory: Sdr::UserVersionService.inventory(druid:))
    Show::VersionsTableComponent.new(versions: versions_presenter.versions, cocina_object:,
                                     druid_token: generate_token(druid))
  end
end
