# frozen_string_literal: true

module MultiItemDeposit
  # Deposit check for a Multi-Item Deposit: checks that each object can still be deposited, recording deposit errors.
  # If there are none, the deposit is submitted and a batch of DepositJobs is enqueued; otherwise, initiating the
  # deposit is completed so the user can review the errors.
  class DepositCheckJob < ApplicationJob
    include ActionPolicy::Behaviour

    # @param multi_item_deposit_action [MultiItemDepositAction]
    # @param effective_groups [Array<String>] the requesting user's authorization workgroups
    def perform(multi_item_deposit_action:, effective_groups:)
      @multi_item_deposit_action = multi_item_deposit_action
      @effective_groups = effective_groups

      item_deposit_actions.each { |item_deposit_action| check(item_deposit_action) }
      return complete_with_errors if deposit_errors?

      start_deposit
    rescue StandardError => e
      handle_error(e)
    end

    private

    attr_reader :multi_item_deposit_action, :effective_groups

    def check(item_deposit_action)
      item_deposit_action.deposit_errors = []
      error_key = error_key_for(item_deposit_action)
      item_deposit_action.deposit_errors << message(:errors, error_key) if error_key
      item_deposit_action.save!
    end

    # @return [Symbol, nil] the first failed check
    def error_key_for(item_deposit_action)
      cocina_object = cocina_objects[item_deposit_action.druid]
      status = statuses[item_deposit_action.druid]
      return :object_not_found if cocina_object.nil? || status.nil?
      return :not_authorized unless update_allowed?(cocina_object)
      return :object_changed if item_deposit_action.content&.lock != cocina_object.lock

      version_error_key(status)
    end

    def version_error_key(status)
      if status.open?
        :not_closeable unless status.closeable?
      else
        :not_openable unless status.openable?
      end
    end

    def deposit_errors?
      item_deposit_actions.any? { |item_deposit_action| item_deposit_action.deposit_errors.any? }
    end

    def complete_with_errors
      multi_item_deposit_action.initiating_deposit_completed!
      broadcast_toast(title: message(:toasts, :errors), user: multi_item_deposit_action.user, variant: :red)
    end

    def start_deposit
      multi_item_deposit_action.update!(step: :submitted)
      SolidQueue::Batch.enqueue(on_finish: DepositFinishJob.new(multi_item_deposit_action:)) do
        item_deposit_actions.each do |item_deposit_action|
          DepositJob.perform_later(item_deposit_action:)
        end
      end
    end

    # Returns the user to the deposit step (e.g., if enqueuing the batch failed after submitting).
    def handle_error(error)
      Rails.logger.error(error.full_message)
      Honeybadger.notify(error)
      # Adding a deposit error to each ItemDepositAction.
      multi_item_deposit_action.item_deposit_actions.update_all(deposit_errors: [message(:errors, :unexpected)]) # rubocop:disable Rails/SkipsModelValidations
      multi_item_deposit_action.reload.step = :deposit
      complete_with_errors
    end

    def update_allowed?(cocina_object)
      Current.set(effective_groups:) do
        allowed_to?(:update?, cocina_object, with: ObjectPolicy, context: { user: multi_item_deposit_action.user })
      end
    end

    def item_deposit_actions
      @item_deposit_actions ||= multi_item_deposit_action.item_deposit_actions.includes(:content).to_a
    end

    def druids
      item_deposit_actions.map(&:druid)
    end

    # @return [Hash<String, Cocina::Models::DROWithMetadata>] the objects, keyed by druid
    def cocina_objects
      @cocina_objects ||= Sdr::Repository.find_all(druids:)
    end

    # @return [Hash<String, Dor::Services::Client::ObjectVersion::VersionStatus>] the version statuses, keyed by druid
    def statuses
      @statuses ||= Sdr::VersionService.statuses(druids:)
    end

    def message(kind, key)
      I18n.t(key, scope: [:multi_item_deposit, :deposit_check, kind])
    end
  end
end
