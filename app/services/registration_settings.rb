# frozen_string_literal: true

# The registration settings of an existing item, copied into the forms for registering new items
# ("Copy registration settings for" on the item show page).
# Identifiers (source ID, catalog record ID, barcode), the description, and the Registered By tag (which
# registering adds for whoever registers) are not copied.
class RegistrationSettings
  # Attributes of the item's cocina model that are copied.
  COPIED_ATTRIBUTES = %i[
    content_type viewing_direction apo_druid collection_druids
    access_view access_download access_location
    embargo_release_date embargo_view embargo_download embargo_location
    use_and_reproduction_statement copyright license
  ].freeze

  # @param cocina_object [Cocina::Models::DROWithMetadata] the item to copy the settings of
  def initialize(cocina_object:)
    @cocina_object = cocina_object
  end

  # The APO and collections let ItemPolicy#create? decide whether the user can register with these settings.
  # @return [String]
  def apo_druid
    cocina_object.administrative.hasAdminPolicy
  end

  # @return [Array<String>]
  def collection_druids
    Array(cocina_object.structural&.isMemberOf)
  end

  # Registering multiple items also chooses whether to deposit with Goobi, which is copied as yes when the item
  # is of a Goobi content type and was registered with Goobi (goobiWF for version 1, not a later Goobi Redeposit).
  # @return [Hash] attributes for ItemsRegistrationForm
  # @raise [Dor::Services::Client::NotFoundResponse, Sdr::AdministrativeTags::NotFoundResponse] if the item is not found
  def items_registration_form_attributes
    common_attributes.merge(deposit_with_goobi: deposited_with_goobi?)
  end

  # Unlike registering multiple items, registering an item also sets its release.
  # Only the item's own release tags are copied, so a target that follows the collection still does.
  # @return [Hash] attributes for NewItemForm
  # @raise [Sdr::Repository::NotFoundResponse, Sdr::AdministrativeTags::NotFoundResponse] if the item is not found
  def new_item_form_attributes
    release_tags = Sdr::Repository.release_tags(druid:, public: false)
    common_attributes.merge(release_tags_attributes: ItemReleaseTagsForm.tagged_choices(release_tags))
  end

  private

  attr_reader :cocina_object

  def druid
    cocina_object.externalIdentifier
  end

  def tags
    Sdr::AdministrativeTags.list(druid:).reject { |tag| tag.start_with?(Sdr::Repository::REGISTERED_BY_TAG_PREFIX) }
  end

  def common_attributes
    CocinaModelMappers::DroMapper.call(cocina_object:)
                                 .slice(*COPIED_ATTRIBUTES)
                                 .merge(TagsFormConcern.tag_fields_attributes(tags))
  end

  def deposited_with_goobi?
    return false unless Sdr::GoobiRedepositService.goobi_content_type?(cocina_object)

    processes = Sdr::WorkflowService.workflows_for(druid:).flat_map(&:processes)
    Sdr::GoobiRedepositService.goobi_started?(processes:, version: 1)
  end
end
