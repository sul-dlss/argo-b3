# frozen_string_literal: true

module MultiItemDeposit
  # Renders the summary of the results of checking a Multi-Item Deposit's files (structuring): when it started,
  # a link to download the report, the number of Item Deposits and of those with structure errors,
  # the number and total size of the files, and their MIME types.
  class StructureSummaryComponent < ApplicationComponent
    # @param multi_item_deposit_action [MultiItemDepositAction]
    # @param summary [StructureResults::Summary] the totals, loaded by the controller
    def initialize(multi_item_deposit_action:, summary:)
      @multi_item_deposit_action = multi_item_deposit_action
      @summary = summary
      super()
    end

    delegate :item_count, :items_with_errors_count, to: :@summary

    def started_at
      helpers.format_datetime(@multi_item_deposit_action.structuring_started_at)
    end

    def report_path
      helpers.structure_report_multi_item_deposit_action_path(@multi_item_deposit_action)
    end

    def error_classes
      items_with_errors_count.positive? ? 'text-danger' : 'text-success'
    end

    # @return [String] e.g., "1,200 files / 58 MB"
    def file_count_and_size
      t('multi_item_deposit.structure_summary.file_count_and_size',
        count: @summary.file_count,
        file_count: helpers.number_with_delimiter(@summary.file_count),
        size: helpers.number_to_human_size(@summary.file_size))
    end

    # @return [String, nil] e.g., "image/jp2, image/tiff"
    def mime_types
      @summary.mime_types.join(', ').presence
    end
  end
end
