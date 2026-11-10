# frozen_string_literal: true

module MultiItemDeposit
  # Renders the summary of the results of checking a Multi-Item Deposit's manifest (discovery): when it started,
  # the number of Item Deposits and discovery errors, and the content types.
  class DiscoverySummaryComponent < ApplicationComponent
    def initialize(multi_item_deposit_action:)
      @multi_item_deposit_action = multi_item_deposit_action
      super()
    end

    def started_at
      helpers.format_datetime(@multi_item_deposit_action.discovery_started_at)
    end

    def item_count
      item_deposit_actions.count
    end

    # @return [Integer] the number of discovery errors, across all Item Deposits
    def error_count
      @error_count ||= item_deposit_actions.pluck(:discovery_errors).sum(&:size)
    end

    def error_classes
      error_count.positive? ? 'text-danger' : 'text-success'
    end

    # @return [String, nil] the display names of the content types, in manifest order (e.g., "Book, image")
    def content_types
      content_types = item_deposit_actions.order(:manifest_line_number).pluck(:content_type).compact.uniq
      content_types.map { |content_type| ContentTypeSupport.display_name(content_type) }
                   .join(', ').upcase_first.presence
    end

    private

    def item_deposit_actions
      @multi_item_deposit_action.item_deposit_actions
    end
  end
end
