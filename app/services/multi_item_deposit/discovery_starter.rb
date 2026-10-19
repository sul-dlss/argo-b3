# frozen_string_literal: true

module MultiItemDeposit
  # Starts discovery for a Multi-Item Deposit: replaces its Item Deposits with one per manifest row and
  # enqueues a batch of DiscoverFilesJobs, whose DiscoverFilesFinishJob completes discovery.
  class DiscoveryStarter
    def self.call(...)
      new(...).call
    end

    # @param multi_item_deposit_action [MultiItemDepositAction]
    # @param discovery_form [DiscoveryForm] a valid discovery form
    # @param effective_groups [Array<String>] the requesting user's authorization workgroups
    def initialize(multi_item_deposit_action:, discovery_form:, effective_groups:)
      @multi_item_deposit_action = multi_item_deposit_action
      @discovery_form = discovery_form
      @effective_groups = effective_groups
    end

    def call
      multi_item_deposit_action.transaction do
        destroy_item_deposit_actions
        multi_item_deposit_action.assign_attributes(**discovery_form.multi_item_deposit_action_attributes,
                                                    structuring_started_at: nil, structuring_completed_at: nil)
        create_item_deposit_actions
        multi_item_deposit_action.discovery_started!
      end
      # The queue is a separate database, so the batch is enqueued after the commit.
      enqueue_discover_files_jobs
    end

    private

    attr_reader :multi_item_deposit_action, :discovery_form, :effective_groups

    delegate :item_deposit_actions, to: :multi_item_deposit_action

    # Contents first, while their ids can still be selected from the Item Deposits.
    def destroy_item_deposit_actions
      Content.where(id: item_deposit_actions.select(:content_id)).destroy_all
      item_deposit_actions.destroy_all
    end

    # Line numbers start at 2 since the header is line 1.
    def create_item_deposit_actions
      CSV.parse(multi_item_deposit_action.manifest_csv, headers: true)
         .each.with_index(2) do |row, manifest_line_number|
        item_deposit_actions.create!(druid: row[ManifestCsv::Validator::DRUID_COLUMN],
                                     path: row[ManifestCsv::Validator::FOLDER_NAME_COLUMN], manifest_line_number:)
      end
    end

    def enqueue_discover_files_jobs
      SolidQueue::Batch.enqueue(on_finish: DiscoverFilesFinishJob.new(multi_item_deposit_action:)) do
        item_deposit_actions.each do |item_deposit_action|
          DiscoverFilesJob.perform_later(item_deposit_action:, effective_groups:)
        end
      end
    end
  end
end
