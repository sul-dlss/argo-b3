# frozen_string_literal: true

module MultiItemDeposit
  # Structuring for one Item Deposit: builds the file sets and files of its mutable Content from the structural
  # metadata CSV (or else a populator), validates the structure for the content type, and records the file changes.
  class StructureJob < ApplicationJob
    # @param item_deposit_action [ItemDepositAction]
    def perform(item_deposit_action:)
      @item_deposit_action = item_deposit_action
      item_deposit_action.assign_attributes(structural_csv_errors: [], content_type_structure_errors: [],
                                            content_type_structure_warnings: [], file_changes: {})

      content.content_file_sets.destroy_all
      structure!
      validate_and_record_changes if item_deposit_action.structural_csv_errors.empty?
      item_deposit_action.save!
    rescue StandardError => e
      handle_error(e)
    end

    private

    attr_reader :item_deposit_action

    delegate :druid, :content, :multi_item_deposit_action, to: :item_deposit_action
    delegate :structural_metadata_csv, to: :multi_item_deposit_action

    def structure!
      if structural_metadata_csv.present?
        import
      else
        populate
      end
    end

    def import
      return add_error(:no_rows) if rows.empty?
      return add_error(:files_not_in_csv, filepaths: missing_filepaths.sort.join(', ')) if missing_filepaths.any?

      StructuralCsv::Import.call(rows:, content:).or { |errors| add_import_errors(errors) }
    end

    # @param errors [Array<StructuralCsv::ValidationError>]
    def add_import_errors(errors)
      item_deposit_action.structural_csv_errors.concat(
        errors.map { |error| "Row #{error.line_number}: #{error.reason}" }
      )
    end

    def populate
      selection = Contents::PopulatorSelector.call(content:, cocina_object:, content_type:)
      selection.actual_populator.structure(content:, cocina_object:)
      return unless multi_item_deposit_action.publish_preserve_all?

      content.content_files.update_all(publish: true, preserve: true, shelve: true) # rubocop:disable Rails/SkipsModelValidations
    end

    def validate_and_record_changes
      content.reload
      result = Contents::Validator.call(content:, cocina_object:, content_type:)
      item_deposit_action.assign_attributes(content_type_structure_errors: result.errors,
                                            content_type_structure_warnings: result.warnings,
                                            file_changes:)
    end

    # Matched by filepath only, so a file in both is counted as updated regardless of whether it changed.
    def file_changes
      filepaths = content.content_file_binaries.associated.pluck(:filepath)
      {
        'added' => (filepaths - existing_filepaths).size,
        'deleted' => (existing_filepaths - filepaths).size,
        'updated' => (filepaths & existing_filepaths).size
      }
    end

    def existing_filepaths
      @existing_filepaths ||= Array(cocina_object.structural&.contains).flat_map do |file_set|
        Array(file_set.structural&.contains).map(&:filename)
      end
    end

    # Rows keep their line numbers in the whole CSV, so that errors refer to the user's spreadsheet.
    # @return [Array<Array(Integer, CSV::Row)>] the rows for this object
    def rows
      @rows ||= CSV.parse(structural_metadata_csv, headers: true).each.with_index(2)
                   .map { |row, number| [number, row] }
                   .select { |_number, row| row['druid'] == druid }
    end

    # Discovered files must all be in the CSV, since StructuralCsv::Import destroys the files that are omitted.
    def missing_filepaths
      @missing_filepaths ||= content.content_file_binaries.pluck(:filepath) -
                             rows.map { |_number, row| row['filename'] }
    end

    # Unsaved changes are discarded, but the errors and warnings so far are kept.
    def handle_error(error)
      Rails.logger.error(error.full_message)
      Honeybadger.notify(error)
      structural_csv_errors = item_deposit_action.structural_csv_errors
      content_type_structure_errors = item_deposit_action.content_type_structure_errors + [message(:unexpected)]
      content_type_structure_warnings = item_deposit_action.content_type_structure_warnings
      item_deposit_action.reload.update!(structural_csv_errors:, content_type_structure_errors:,
                                         content_type_structure_warnings:, file_changes: {})
    end

    def cocina_object
      @cocina_object ||= Sdr::Repository.find(druid:)
    end

    # The stored content type is the short name (e.g., book), whereas a cocina type URI is expected.
    def content_type
      Cocina::Models::ObjectType[item_deposit_action.content_type]
    end

    def add_error(key, **)
      item_deposit_action.structural_csv_errors << message(key, **)
    end

    def message(key, **)
      I18n.t(key, scope: %i[multi_item_deposit structure errors], **)
    end
  end
end
