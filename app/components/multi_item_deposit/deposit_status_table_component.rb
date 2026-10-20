# frozen_string_literal: true

module MultiItemDeposit
  # Renders the deposit status of a Multi-Item Deposit's Item Deposits.
  class DepositStatusTableComponent < ApplicationComponent
    # @param object_status_presenters [Array<ObjectStatusPresenter>] the Item Deposits' objects, in display order
    def initialize(object_status_presenters:)
      @object_status_presenters = object_status_presenters
      super()
    end

    attr_reader :object_status_presenters

    def values_for(object_status_presenter)
      [druid_link(object_status_presenter), status(object_status_presenter)]
    end

    def label
      t('multi_item_deposit.deposit_status.label')
    end

    private

    def druid_link(object_status_presenter)
      helpers.link_to_object(object_status_presenter.bare_druid, object_status_presenter.druid)
    end

    def status(object_status_presenter)
      render(Show::StatusLabelComponent.new(status: object_status_presenter.status))
    end
  end
end
