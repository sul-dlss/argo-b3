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

  DISPLAY_STATUSES = {
    'submitted' => 'Submitted',
    'initiating_deposit' => 'Initiating deposit',
    'discovering' => 'Discovering files',
    'structuring' => 'Checking files',
    'not_submitted' => 'Not submitted'
  }.freeze

  # The conditions of the display statuses in order of precedence; a display status applies only when
  # none of the preceding ones do. Not submitted (nil) applies when none of the others do.
  DISPLAY_STATUS_CONDITIONS = {
    'submitted' => { step: 'submitted' },
    'initiating_deposit' => { initiating_deposit_state: 'initiating_depositing' },
    'discovering' => { discovery_state: 'discovering' },
    'structuring' => { structuring_state: 'structuring' },
    'not_submitted' => nil
  }.freeze

  enum :file_location, { globus: 'globus', mount: 'mount' }, prefix: true, validate: true
  enum :step, { discovery: 'discovery', structure: 'structure', deposit: 'deposit', submitted: 'submitted' },
       suffix: true, validate: true
  enum :manifest_source, { mount: 'mount', upload: 'upload' }, prefix: true, validate: true
  enum :structural_metadata_csv_source, { mount: 'mount', upload: 'upload' }, prefix: true,
                                                                              validate: { allow_nil: true }

  # @param display_statuses [Array<String>] keys of DISPLAY_STATUSES (others are ignored)
  # @return [ActiveRecord::Relation] the Multi-Item Deposits with any of the display statuses
  def self.with_display_statuses(display_statuses)
    (display_statuses & DISPLAY_STATUSES.keys).map { |display_status| where_display_status(display_status) }
                                              .reduce(:or) || none
  end

  # @param statuses [Array<String>, nil] keys of DISPLAY_STATUSES; nil for no limit
  # @param submitted_since [ActiveSupport::TimeWithZone, nil] nil for no limit
  # @param user_ids [Array<String>, nil] nil for no limit
  # @return [ActiveRecord::Relation] the Multi-Item Deposits that match the filters
  def self.filtered(statuses: nil, submitted_since: nil, user_ids: nil)
    relation = all
    relation = relation.where(user_id: user_ids) if user_ids
    relation = relation.with_display_statuses(statuses) if statuses
    relation = relation.where(initiating_deposit_completed_at: submitted_since..) if submitted_since
    relation
  end

  def self.where_display_status(display_status)
    preceding_conditions = DISPLAY_STATUS_CONDITIONS.values.take(DISPLAY_STATUS_CONDITIONS.keys.index(display_status))
    relation = preceding_conditions.reduce(all) { |partial_relation, condition| partial_relation.where.not(condition) }
    condition = DISPLAY_STATUS_CONDITIONS[display_status]
    condition ? relation.where(condition) : relation
  end
  private_class_method :where_display_status

  # @return [String] the key of the Multi-Item Deposit's DISPLAY_STATUSES
  def display_status
    DISPLAY_STATUS_CONDITIONS.find do |_display_status, condition|
      condition.nil? || condition.all? { |attribute, value| public_send(attribute) == value }
    end.first
  end

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

  # @return [String, nil] the directory the files are in: the mount path, or the Globus directory on the local
  #   Globus mount
  def files_path
    file_location_globus? ? globus_directory&.local_path : mount_path.presence
  end

  # @return [String, nil] the path of the structural metadata CSV at the root of the files path, if it exists
  def mount_structural_metadata_csv_path
    return if files_path.nil?

    path = File.join(files_path, STRUCTURAL_METADATA_CSV_FILENAME)
    path if File.file?(path)
  end

  # @return [GlobusDirectory, nil] the Globus directory created for transferring files, if any
  def globus_directory
    GlobusDirectory.new(path: globus_path, user:) if globus_path.present?
  end

  # Creates the Globus directory for transferring files, unless already created (e.g., a double submit).
  # @return [Boolean] true if the directory exists; false if Globus returned an error
  def create_globus_directory!
    return true if globus_path.present?

    new_globus_directory = GlobusDirectory.for_multi_item_deposit(user:)
    return false unless new_globus_directory.create

    update!(globus_path: new_globus_directory.path)
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
