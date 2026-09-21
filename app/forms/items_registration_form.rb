# frozen_string_literal: true

# Form object for registering multiple Items (DROs)
class ItemsRegistrationForm < ApplicationForm
  include PermittedParamsConcern
  include PrevalidationConcern
  include CocinaModels::AccessConcern
  include CocinaModels::ContentTypeConcern
  include CocinaModels::ApoConcern
  include CocinaModels::EmbargoConcern
  include EmbargoFormConcern
  include TagsFormConcern

  UPLOAD_CSV_CHOICE = 'upload_csv'
  ENTER_TAB_DELIMITED_CHOICE = 'enter_tab_delimited'
  ENTER_EACH_CHOICE = 'enter_each'

  # Attribute that item presence errors are reported for, by items choice, so that the error is
  # displayed in the section that the user entered items in.
  ITEMS_CHOICE_ERROR_ATTRIBUTES = { UPLOAD_CSV_CHOICE => :csv_file,
                                    ENTER_TAB_DELIMITED_CHOICE => :tab_delimited_items,
                                    ENTER_EACH_CHOICE => :item_registrations }.freeze

  # Columns of the tab-delimited list, in order.
  TAB_DELIMITED_FIELDS = %i[barcode catalog_record_id source_id title].freeze

  # Columns of the uploaded CSV mapped to the fields of an item registration.
  CSV_FIELDS = { 'barcode' => :barcode, 'folio_instance_hrid' => :catalog_record_id,
                 'source_id' => :source_id, 'title' => :title }.freeze

  CSV_REQUIRED_HEADERS = %w[source_id].freeze

  attribute :items_choice, :string, default: ENTER_EACH_CHOICE

  attribute :tab_delimited_items, :string
  before_validation :build_item_registrations_from_tab_delimited_items

  attribute :csv_file, :uploaded_file
  attribute :csv, :string # csv_file normalized and converted to a string by ItemsRegistrationFormSerializer
  before_validation :build_item_registrations_from_csv
  validate :csv_must_be_valid

  has_many :item_registrations, class_name: 'ItemRegistrationForm'
  before_validation :remove_blank_item_registrations
  validate :item_registrations_presence

  attribute :tags, default: -> { [] }

  # csv is derived from csv_file rather than submitted by the user.
  # tags are derived from various tag fields.
  def self.immutable_attributes
    %i[csv tags]
  end

  def initialize(attributes = {})
    super
    derive_with_embargo
  end

  # The item registrations that the user is asked to fix. When the problem is with how the items were
  # entered rather than with the items themselves, none of them are, since the item registrations
  # derived from a faulty entry are not worth fixing one by one.
  # @return [Array<ItemRegistrationForm>] the item registrations that have validation errors
  def invalid_item_registrations
    return [] if items_entry_error?

    @invalid_item_registrations ||= item_registrations.to_a.select { |item_registration| item_registration.errors.any? }
  end

  private

  # Replaces the item registrations with ones parsed from the tab-delimited items.
  # Rows with fewer than TAB_DELIMITED_FIELDS.size values leave the trailing fields blank (and so will
  # generally fail ItemRegistrationForm's own validations); extra values are ignored.
  def build_item_registrations_from_tab_delimited_items
    return unless items_choice == ENTER_TAB_DELIMITED_CHOICE

    item_registrations.clear
    tab_delimited_items.to_s.each_line do |line|
      next if line.blank?

      values = line.chomp.split("\t")
      item_registrations.build(TAB_DELIMITED_FIELDS.zip(values).to_h)
    end
  end

  # Replaces the item registrations with ones parsed from the uploaded CSV.
  # Columns that are missing from the CSV leave their fields blank (and so will generally fail
  # ItemRegistrationForm's own validations); extra columns are ignored.
  # Nothing is built from an invalid CSV, since csv_must_be_valid reports the error instead and the
  # item registrations derived from it are not worth fixing one by one.
  def build_item_registrations_from_csv
    return unless items_choice == UPLOAD_CSV_CHOICE
    return if csv.blank?
    return unless csv_valid?

    item_registrations.clear
    CSV.parse(csv, headers: true).each do |row|
      item_registrations.build(CSV_FIELDS.to_h { |header, field| [field, row[header]] })
    end
  end

  # Discards item registrations left blank by the user, unless every one of them is blank
  # (in which case item_registrations_presence should report the error instead).
  def remove_blank_item_registrations
    blank_item_registrations = item_registrations.select(&:empty?)
    return if blank_item_registrations.empty? || blank_item_registrations.size == item_registrations.size

    present_item_registrations = item_registrations.to_a - blank_item_registrations
    item_registrations.clear
    present_item_registrations.each { |item_registration| item_registrations.push(item_registration) }
  end

  # Errors are reported for csv_file rather than csv since csv_file is the field the user provides.
  def csv_must_be_valid
    return unless items_choice == UPLOAD_CSV_CHOICE
    return errors.add(:csv_file, :blank) if csv.blank?

    return if csv_valid?

    csv_validator.errors.each do |message|
      errors.add(:csv_file, :invalid, message:)
    end
  end

  def csv_validator
    @csv_validator ||= CsvUpload::Validator.new(csv:, required_headers: CSV_REQUIRED_HEADERS)
  end

  # CsvUpload::Validator#valid? appends to its errors on each call, so the result is memoized.
  def csv_valid?
    return @csv_valid if defined?(@csv_valid)

    @csv_valid = csv_validator.valid?
  end

  def item_registrations_presence
    # When the CSV is missing or invalid, csv_must_be_valid reports the error instead.
    return if errors[:csv_file].any?
    return if item_registrations.to_a.any? { |item_registration| !item_registration.empty? }

    errors.add(items_choice_error_attribute, I18n.t('edit.multiple_items.validations.no_items'))
  end

  # Whether the error is with how the items were entered (e.g., a CSV with missing headers, or no items
  # at all) rather than with the individual items. csv_must_be_valid or item_registrations_presence
  # reports the error in that case, and the view shows the item entry fields rather than the items.
  def items_entry_error?
    errors[:csv_file].any? || errors[:tab_delimited_items].any? || item_registrations.to_a.all?(&:empty?)
  end

  def items_choice_error_attribute
    ITEMS_CHOICE_ERROR_ATTRIBUTES.fetch(items_choice, :item_registrations)
  end
end
