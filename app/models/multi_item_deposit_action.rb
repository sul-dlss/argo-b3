# frozen_string_literal: true

# Model for a Multi-Item Deposit: a user-run deposit of many Items, carried out in steps.
# A step is complete when its *_completed_at is set (by its state machine's transition);
# failures are recorded on the ItemDepositActions.
class MultiItemDepositAction < ApplicationRecord
  belongs_to :user
  has_many :item_deposit_actions, dependent: :destroy

  # Item Deposit content types are stored as the last segment of the cocina type URI.
  OCR_CONTENT_TYPES = Sdr::TextExtraction::SUPPORTED_TYPES.map { |type| UriSupport.last(uri: type) }.freeze
  STRUCTURAL_METADATA_CSV_REQUIRED_CONTENT_TYPES = [UriSupport.last(uri: Cocina::Models::ObjectType.media)].freeze
  STRUCTURAL_METADATA_CSV_FILENAME = 'structural_metadata.csv'

  enum :file_location, { globus: 'globus', mount: 'mount' }, prefix: true, validate: true
  enum :step, { discovery: 'discovery', structure: 'structure', deposit: 'deposit', submitted: 'submitted' },
       suffix: true, validate: true
  enum :manifest_source, { mount: 'mount', upload: 'upload' }, prefix: true, validate: true
  enum :structural_metadata_csv_source, { mount: 'mount', upload: 'upload' }, prefix: true,
                                                                              validate: { allow_nil: true }

  # @return [ActiveRecord::Relation<ItemDepositAction>] the Item Deposits with discovery errors or warnings
  def item_deposit_actions_with_discovery_errors_or_warnings
    item_deposit_actions.merge(ItemDepositAction.with_discovery_errors.or(ItemDepositAction.with_discovery_warnings))
                        .order(:manifest_line_number)
  end

  # Discovery has completed and found no errors, so the deposit can proceed to the structure step.
  def discovery_succeeded?
    discovery_completed_at.present? && item_deposit_actions.with_discovery_errors.none?
  end

  # Structuring has completed and found no errors, so the deposit can proceed to the deposit step.
  def structuring_succeeded?
    structuring_completed_at.present? && item_deposit_actions.with_structure_errors.none?
  end

  # @return [Boolean] whether any Item Deposit has a content type that can be OCRed
  def ocr_applicable?
    item_deposit_actions.exists?(content_type: OCR_CONTENT_TYPES)
  end

  # @return [Boolean] whether any Item Deposit has a content type that can only be structured from a CSV
  def structural_metadata_csv_required?
    item_deposit_actions.exists?(content_type: STRUCTURAL_METADATA_CSV_REQUIRED_CONTENT_TYPES)
  end

  # @return [Boolean] whether every Item Deposit is an initial version
  def all_initial_versions?
    !item_deposit_actions.exists?(initial_version: [false, nil])
  end

  # @return [String, nil] the path of the structural metadata CSV at the root of the mount path, if it exists
  def mount_structural_metadata_csv_path
    return if mount_path.blank?

    path = File.join(mount_path, STRUCTURAL_METADATA_CSV_FILENAME)
    path if File.file?(path)
  end

  state_machine :discovery_state, initial: :discovery_not_in_progress do
    event :discovery_started do
      transition discovery_not_in_progress: :discovering
    end

    event :discovery_completed do
      transition discovering: :discovery_not_in_progress
    end

    before_transition on: :discovery_started do |multi_item_deposit_action|
      multi_item_deposit_action.assign_attributes(discovery_started_at: Time.current, discovery_completed_at: nil)
    end

    before_transition on: :discovery_completed do |multi_item_deposit_action|
      multi_item_deposit_action.discovery_completed_at = Time.current
    end
  end

  state_machine :structuring_state, initial: :structuring_not_in_progress do
    event :structuring_started do
      transition structuring_not_in_progress: :structuring
    end

    event :structuring_completed do
      transition structuring: :structuring_not_in_progress
    end

    before_transition on: :structuring_started do |multi_item_deposit_action|
      multi_item_deposit_action.assign_attributes(structuring_started_at: Time.current, structuring_completed_at: nil)
    end

    before_transition on: :structuring_completed do |multi_item_deposit_action|
      multi_item_deposit_action.structuring_completed_at = Time.current
    end
  end

  state_machine :initiating_deposit_state, initial: :initiating_deposit_not_in_progress do
    event :initiating_deposit_started do
      transition initiating_deposit_not_in_progress: :initiating_depositing
    end

    event :initiating_deposit_completed do
      transition initiating_depositing: :initiating_deposit_not_in_progress
    end

    before_transition on: :initiating_deposit_started do |multi_item_deposit_action|
      multi_item_deposit_action.assign_attributes(initiating_deposit_started_at: Time.current,
                                                  initiating_deposit_completed_at: nil)
    end

    before_transition on: :initiating_deposit_completed do |multi_item_deposit_action|
      multi_item_deposit_action.initiating_deposit_completed_at = Time.current
    end
  end

  def name
    name = "Multi-item deposit #{id}"
    return name if description.blank?

    "#{name}: #{description}"
  end
end
