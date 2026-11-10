# frozen_string_literal: true

module MultiItemDeposit
  # Renders the summary of the results of checking a Multi-Item Deposit's manifest (discovery): when it started,
  # the number of Item Deposits and of those with discovery errors, and the content types.
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

    # The Item Deposits with discovery errors, as in MultiItemDepositAction#discovery_succeeded?
    # @return [Integer]
    def items_with_errors_count
      @items_with_errors_count ||= item_deposit_actions.with_discovery_errors.count
    end

    def error_classes
      items_with_errors_count.positive? ? 'text-danger' : 'text-success'
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
