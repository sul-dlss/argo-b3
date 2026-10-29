# frozen_string_literal: true

module MultiItemDeposit
  # Form for the discovery step of a multi-item deposit.
  class DiscoveryForm < ApplicationForm
    MANIFEST_FILENAME = 'manifest.csv'

    inherit_attributes_from MultiItemDepositAction, only: %i[description mount_path]
    normalizes_whitespace :description, :mount_path

    attribute :file_location, :string, default: MultiItemDepositAction.file_locations[:mount]
    validates :file_location, inclusion: { in: MultiItemDepositAction.file_locations.values }
    validates :mount_path, presence: true, mount_path: true, if: :mount_file_location?

    # The deposit, which is not an attribute so that it is not a permitted param (e.g., its Globus path).
    # Needed to support knowing which Globus folder to read.
    attr_accessor :multi_item_deposit_action

    delegate :globus_path, :globus_directory, to: :multi_item_deposit_action, allow_nil: true
    # Validated before the manifest, whose checks are skipped when the Globus path has errors.
    validate :globus_path_must_be_present, if: :globus_file_location?

    attribute :manifest_source, :string, default: MultiItemDepositAction.manifest_sources[:upload]
    validates :manifest_source, inclusion: { in: MultiItemDepositAction.manifest_sources.values }

    attribute :manifest_file, :uploaded_file
    # The manifest provided earlier: saved, or carried by a re-rendered form.
    attribute :manifest_csv, :string
    validate :uploaded_manifest_must_be_readable, if: :upload_manifest_source?
    validate :mount_manifest_must_exist, if: -> { mount_manifest_source? && files_path_errors.empty? }
    validate :manifest_csv_must_be_valid, if: :manifest_found?

    # @return [String, nil] the normalized manifest for this submit: a newly uploaded file, else the manifest
    #   provided earlier; or the manifest at the root of the mount path
    def submitted_manifest_csv
      return manifest_csv.presence if upload_manifest_source? && manifest_file.blank?
      return unless manifest_filepath

      @submitted_manifest_csv ||= CsvUpload::Normalizer.read(manifest_filepath)
    end

    # @return [String, nil] the uploaded manifest, which a re-rendered form need not upload again
    def retainable_manifest_csv
      submitted_manifest_csv if upload_manifest_source?
    rescue CsvUpload::Normalizer::Error
      nil
    end

    # @param multi_item_deposit_action [MultiItemDepositAction]
    # @return [Boolean] whether the uploaded manifest is not saved, so a re-rendered form must carry it
    def unsaved_manifest_csv?(multi_item_deposit_action)
      retainable_manifest_csv.present? && retainable_manifest_csv != multi_item_deposit_action.manifest_csv
    end

    # @return [Hash] the attributes to save on the MultiItemDepositAction
    def multi_item_deposit_action_attributes
      { description:, file_location:, mount_path: (mount_path if mount_file_location?), manifest_source:,
        manifest_csv: submitted_manifest_csv }
    end

    private

    def mount_file_location?
      file_location == MultiItemDepositAction.file_locations[:mount]
    end

    def globus_file_location?
      file_location == MultiItemDepositAction.file_locations[:globus]
    end

    # @return [String, nil] the directory the files are in: the mount path, or the Globus directory on the local
    #   Globus mount
    def files_path
      return mount_path if mount_file_location?

      globus_directory&.local_path if globus_file_location?
    end

    def files_path_errors
      errors[:mount_path] + errors[:globus_path]
    end

    def manifest_found?
      files_path_errors.empty? && errors[manifest_attribute].empty?
    end

    def upload_manifest_source?
      manifest_source == MultiItemDepositAction.manifest_sources[:upload]
    end

    def mount_manifest_source?
      manifest_source == MultiItemDepositAction.manifest_sources[:mount]
    end

    def manifest_filepath
      return manifest_file&.path if upload_manifest_source?

      File.join(files_path, MANIFEST_FILENAME) if mount_manifest_source? && files_path.present?
    end

    # Errors go on the field the user provided the manifest with.
    def manifest_attribute
      upload_manifest_source? ? :manifest_file : :manifest_source
    end

    def mount_manifest_must_exist
      return if manifest_filepath && File.file?(manifest_filepath)

      errors.add(:manifest_source,
                 I18n.t('edit.multi_item_deposits.fields.manifest_source.validations.manifest_not_found',
                        filename: MANIFEST_FILENAME))
    end

    def manifest_csv_must_be_valid
      return if submitted_manifest_csv.nil?

      validator = ManifestCsv::Validator.new(csv: submitted_manifest_csv, files_path:)
      return if validator.valid?

      validator.errors.each { |message| errors.add(manifest_attribute, message) }
    rescue CsvUpload::Normalizer::Error => e
      errors.add(manifest_attribute, :invalid, message: e.message)
    end

    def globus_path_must_be_present
      return if globus_path.present?

      errors.add(:globus_path, I18n.t('edit.multi_item_deposits.fields.globus_path.validations.blank'))
    end

    def uploaded_manifest_must_be_readable
      errors.add(:manifest_file, :blank) if submitted_manifest_csv.blank?
    rescue CsvUpload::Normalizer::Error => e
      errors.add(:manifest_file, :invalid, message: e.message)
    end
  end
end
