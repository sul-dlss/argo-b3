# frozen_string_literal: true

module MultiItemDeposit
  # Renders how many of a Multi-Item Deposit's Item Deposits have each deposit status, in a live region.
  class DepositStatusCountsComponent < ApplicationComponent
    # @param object_status_presenters [Array<ObjectStatusPresenter>] the Item Deposits' objects
    def initialize(object_status_presenters:)
      @object_status_presenters = object_status_presenters
      super()
    end

    def call
      tag.p(id: 'deposit-status-counts', role: 'status') { safe_join(counts, '; ') }
    end

    private

    attr_reader :object_status_presenters

    def counts
      tally = object_status_presenters.map(&:status).tally
      # A fixed order, so the text (and so the announcement) changes only when the counts do.
      status_counts = ObjectStatusPresenter::STATUSES.filter_map do |status|
        "#{status_label(status)}: #{helpers.number_with_delimiter(tally[status])}" if tally.key?(status)
      end
      total = helpers.number_with_delimiter(object_status_presenters.size)
      ["#{t('multi_item_deposit.deposit_status.total')}: #{total}", *status_counts]
    end

    # Drops the ellipsis of in-progress headings (e.g., "Depositing..."), which reads oddly before a count.
    def status_label(status)
      t("show.status.#{status}.heading").delete_suffix('...')
    end
  end
end
