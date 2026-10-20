# frozen_string_literal: true

module MultiItemDeposit
  # Builds the ObjectStatusPresenters for a Multi-Item Deposit's Item Deposits, retrieving the Solr docs
  # and version statuses in bulk.
  class ObjectStatusPresentersBuilder
    FIELDS = [Search::Fields::ID, Search::Fields::WORKFLOW_ERRORS].freeze

    def self.call(...)
      new(...).call
    end

    # @param item_deposit_actions [Enumerable<ItemDepositAction>] the Item Deposits, in display order
    # @param initiating [Boolean] true if the Multi-Item Deposit's deposit is being initiated
    def initialize(item_deposit_actions:, initiating:)
      @item_deposit_actions = item_deposit_actions
      @initiating = initiating
    end

    # @return [Array<ObjectStatusPresenter>] in the order of the Item Deposits, omitting any without a Solr doc
    def call
      return [] if druids.empty?

      item_deposit_actions.filter_map do |item_deposit_action|
        druid = item_deposit_action.druid
        document = documents_by_druid[druid]
        next unless document

        ObjectStatusPresenter.new(document:,
                                  version_service: Sdr::VersionService.new(druid:, status: version_statuses[druid]),
                                  content: item_deposit_action.content,
                                  initiating: initiating?(item_deposit_action))
      end
    end

    private

    attr_reader :item_deposit_actions, :initiating

    # An Item Deposit with deposit errors has failed rather than waiting to be initiated.
    def initiating?(item_deposit_action)
      initiating && item_deposit_action.deposit_errors.empty?
    end

    def druids
      @druids ||= item_deposit_actions.map(&:druid)
    end

    # The owner of the Multi-Item Deposit was authorized for these objects during discovery.
    def documents_by_druid
      @documents_by_druid ||= Searchers::ItemByDruid.call(druids:, user_scope: nil, fields: FIELDS)
                                                    .index_by(&:druid)
    end

    def version_statuses
      @version_statuses ||= Sdr::VersionService.statuses(druids:)
    end
  end
end
