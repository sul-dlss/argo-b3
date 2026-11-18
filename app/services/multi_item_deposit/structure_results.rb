# frozen_string_literal: true

module MultiItemDeposit
  # The results of checking a Multi-Item Deposit's files (structuring), as shown in its summary, summary table and
  # report.
  class StructureResults
    # The totals shown in the summary of the results.
    # @!attribute item_count [Integer] the number of Item Deposits
    # @!attribute items_with_errors_count [Integer] the number of Item Deposits with structure errors
    # @!attribute file_count [Integer] the number of files discovered for the Item Deposits
    # @!attribute file_size [Integer] the total size in bytes of those files
    # @!attribute mime_types [Array<String>] each MIME type of those files once, alphabetically
    Summary = Data.define(:item_count, :items_with_errors_count, :file_count, :file_size, :mime_types)

    # @param multi_item_deposit_action [MultiItemDepositAction]
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
    end

    # @return [Array<ItemDepositAction>] the Item Deposits with errors, then with warnings, then the rest;
    #   each in manifest order
    def item_deposit_actions
      @item_deposit_actions ||= @multi_item_deposit_action.item_deposit_actions.sort_by do |action|
        [status_rank(action), action.manifest_line_number]
      end
    end

    # @return [Integer] the number of files discovered for the Item Deposit
    def file_count(item_deposit_action)
      file_counts_by_content_id.fetch(item_deposit_action.content_id, 0)
    end

    # The file count is the sum of the summary table's counts.
    # @return [Summary]
    def summary
      Summary.new(item_count: item_deposit_actions.size,
                  items_with_errors_count:,
                  file_count: file_counts_by_content_id.values.sum,
                  file_size: content_file_binaries.sum(:size),
                  mime_types:)
    end

    private

    # Warnings don't count, as in the summary table, where only errors make an Item Deposit's status not OK.
    def items_with_errors_count
      item_deposit_actions.count { |item_deposit_action| item_deposit_action.structure_errors.any? }
    end

    def mime_types
      content_file_binaries.distinct.pluck(:mime_type).compact.sort
    end

    def status_rank(item_deposit_action)
      return 0 if item_deposit_action.structure_errors.any?
      return 1 if item_deposit_action.content_type_structure_warnings.any?

      2
    end

    def content_file_binaries
      ContentFileBinary.where(content_id: item_deposit_actions.filter_map(&:content_id))
    end

    # Counted in one query rather than one per row.
    def file_counts_by_content_id
      @file_counts_by_content_id ||= content_file_binaries.group(:content_id).count
    end
  end
end
