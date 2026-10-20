# frozen_string_literal: true

module MultiItemDeposit
  # Form for the structuring step of a multi-item deposit.
  class StructureForm < ApplicationForm
    include TextExtractionConcern

    UPLOAD_CHOICE = MultiItemDepositAction.structural_metadata_csv_sources[:upload]
    MOUNT_CHOICE = MultiItemDepositAction.structural_metadata_csv_sources[:mount]
    NONE_CHOICE = 'none'

    attribute :publish_preserve_all, :boolean, default: false

    attribute :structural_metadata_csv_choice, :string, default: NONE_CHOICE
    validates :structural_metadata_csv_choice, inclusion: { in: [UPLOAD_CHOICE, MOUNT_CHOICE, NONE_CHOICE] }
    validate :structural_metadata_csv_must_be_provided, if: :none_choice?

    attribute :structural_metadata_csv_file, :uploaded_file
    # The structural metadata CSV uploaded earlier: saved, or carried by a re-rendered form.
    attribute :structural_metadata_csv, :string
    validate :uploaded_structural_metadata_csv_must_be_present, if: :upload_choice?
    validate :mount_structural_metadata_csv_must_exist, if: :mount_choice?
    validate :structural_metadata_csv_must_be_valid, if: -> { csv_attribute && errors[csv_attribute].empty? }

    # The deposit, which is not an attribute so that it is not a permitted param.
    attr_accessor :multi_item_deposit_action

    delegate :mount_structural_metadata_csv_path, :structural_metadata_csv_required?,
             to: :multi_item_deposit_action, allow_nil: true

    def from_model(multi_item_deposit_action)
      super
      self.multi_item_deposit_action = multi_item_deposit_action
      prefill_ocr_settings(multi_item_deposit_action)
      self.structural_metadata_csv = nil unless multi_item_deposit_action.structural_metadata_csv_source_upload?
      self.structural_metadata_csv_choice = default_structural_metadata_csv_choice
      self
    end

    # @return [String, nil] the normalized structural metadata CSV for this submit: a newly uploaded file, else the
    #   CSV uploaded earlier; or the CSV at the root of the mount path
    def submitted_structural_metadata_csv
      return structural_metadata_csv.presence if upload_choice? && structural_metadata_csv_file.blank?
      return unless submitted_filepath

      @submitted_structural_metadata_csv ||= CsvUpload::Normalizer.read(submitted_filepath)
    end

    # @return [String, nil] the uploaded CSV, which a re-rendered form need not upload again
    def retainable_structural_metadata_csv
      submitted_structural_metadata_csv if upload_choice?
    rescue CsvUpload::Normalizer::Error
      nil
    end

    # @return [Boolean] whether the uploaded CSV is not saved, so a re-rendered form must carry it
    def unsaved_structural_metadata_csv?
      retainable_structural_metadata_csv.present? &&
        retainable_structural_metadata_csv != multi_item_deposit_action&.structural_metadata_csv
    end

    # @return [Hash] the attributes to save on the MultiItemDepositAction
    def multi_item_deposit_action_attributes
      ocr_settings_attributes.merge(structural_metadata_attributes)
    end

    private

    def upload_choice?
      structural_metadata_csv_choice == UPLOAD_CHOICE
    end

    def mount_choice?
      structural_metadata_csv_choice == MOUNT_CHOICE
    end

    def none_choice?
      structural_metadata_csv_choice == NONE_CHOICE
    end

    def structural_metadata_attributes
      if none_choice?
        return { structural_metadata_csv: nil, structural_metadata_csv_source: nil, publish_preserve_all: }
      end

      { structural_metadata_csv: submitted_structural_metadata_csv,
        structural_metadata_csv_source: structural_metadata_csv_choice, publish_preserve_all: false }
    end

    # A saved mount CSV is the default only while the file is still on the mount. No CSV was saved for a
    # structure that has been built without one.
    def default_structural_metadata_csv_choice
      saved_source = multi_item_deposit_action.structural_metadata_csv_source
      return saved_source if saved_source == UPLOAD_CHOICE
      return NONE_CHOICE if saved_source.nil? && built_without_csv?
      return MOUNT_CHOICE if mount_structural_metadata_csv_path
      return UPLOAD_CHOICE if structural_metadata_csv_required?

      NONE_CHOICE
    end

    def built_without_csv?
      multi_item_deposit_action.structuring_started_at.present? && !structural_metadata_csv_required?
    end

    def submitted_filepath
      return structural_metadata_csv_file&.path if upload_choice?

      mount_structural_metadata_csv_path if mount_choice?
    end

    # Errors go on the field the user provided the CSV with.
    def csv_attribute
      return :structural_metadata_csv_file if upload_choice?

      :structural_metadata_csv_choice if mount_choice?
    end

    def structural_metadata_csv_must_be_provided
      return unless structural_metadata_csv_required?

      errors.add(:structural_metadata_csv_choice,
                 I18n.t('edit.multi_item_deposits.fields.structural_metadata_csv_choice.validations.required'))
    end

    def uploaded_structural_metadata_csv_must_be_present
      errors.add(:structural_metadata_csv_file, :blank) if submitted_structural_metadata_csv.blank?
    rescue CsvUpload::Normalizer::Error
      # Reported by structural_metadata_csv_must_be_valid.
      nil
    end

    def mount_structural_metadata_csv_must_exist
      return if mount_structural_metadata_csv_path

      errors.add(:structural_metadata_csv_choice,
                 I18n.t('edit.multi_item_deposits.fields.structural_metadata_csv_choice.validations.not_found',
                        filename: MultiItemDepositAction::STRUCTURAL_METADATA_CSV_FILENAME))
    end

    def structural_metadata_csv_must_be_valid
      csv = submitted_structural_metadata_csv
      return if csv.blank?

      validator = CsvUpload::Validator.new(csv:, required_headers: StructuralCsv::Validator::REQUIRED_COLUMNS)
      return if validator.valid?

      validator.errors.each { |message| errors.add(csv_attribute, :invalid, message:) }
    rescue CsvUpload::Normalizer::Error => e
      errors.add(csv_attribute, :invalid, message: e.message)
    end
  end
end
