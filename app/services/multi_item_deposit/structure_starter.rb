# frozen_string_literal: true

module MultiItemDeposit
  # Starts structuring for a Multi-Item Deposit: saves the structure settings and enqueues a batch of
  # StructureJobs, whose StructureFinishJob completes structuring.
  class StructureStarter
    def self.call(...)
      new(...).call
    end

    # @param multi_item_deposit_action [MultiItemDepositAction]
    # @param structure_form [StructureForm] a valid structure form
    def initialize(multi_item_deposit_action:, structure_form:)
      @multi_item_deposit_action = multi_item_deposit_action
      @structure_form = structure_form
    end

    def call
      multi_item_deposit_action.assign_attributes(structure_form.multi_item_deposit_action_attributes)
      multi_item_deposit_action.structuring_started!
      # The queue is a separate database, so the batch is enqueued after saving.
      enqueue_structure_jobs
    end

    private

    attr_reader :multi_item_deposit_action, :structure_form

    def enqueue_structure_jobs
      SolidQueue::Batch.enqueue(on_finish: StructureFinishJob.new(multi_item_deposit_action:)) do
        multi_item_deposit_action.item_deposit_actions.each do |item_deposit_action|
          StructureJob.perform_later(item_deposit_action:)
        end
      end
    end
  end
end
