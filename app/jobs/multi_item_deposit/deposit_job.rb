# frozen_string_literal: true

module MultiItemDeposit
  # Deposit for a Multi-Item Deposit: checks that each object can still be deposited, recording deposit errors.
  # If there are none, the deposit is submitted and each Item Deposit is deposited: a version is opened as necessary
  # and its mutable Content is staged to the assembly location for accessioning.
  class DepositJob < ApplicationJob
    include ActionPolicy::Behaviour

    # @param multi_item_deposit_action [MultiItemDepositAction]
    # @param effective_groups [Array<String>] the requesting user's authorization workgroups
    def perform(multi_item_deposit_action:, effective_groups:)
      @multi_item_deposit_action = multi_item_deposit_action
      @effective_groups = effective_groups

      return unless can_deposit_all?

      multi_item_deposit_action.update!(step: :submitted)
      item_deposit_actions.each { |item_deposit_action| deposit(item_deposit_action) }
      multi_item_deposit_action.initiating_deposit_completed!
      broadcast_toast(title: message(:toasts, :started), user:)
    end

    private

    attr_reader :multi_item_deposit_action, :effective_groups

    delegate :user, :version_description, to: :multi_item_deposit_action

    # @return [Boolean] true if every object can be deposited; otherwise, initiating the deposit is completed
    #   so the user can review the errors
    def can_deposit_all?
      item_deposit_actions.each { |item_deposit_action| check(item_deposit_action) }
      return true unless deposit_errors?

      complete_with_errors
      false
    rescue StandardError => e
      handle_error(e)
      false
    end

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
      return :object_changed unless LockSupport.same?(item_deposit_action.content&.lock, cocina_object.lock)

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
      broadcast_toast(title: message(:toasts, :errors), user:, variant: :red)
    end

    # A failure is recorded on the Item Deposit, so that the other Item Deposits are still deposited.
    def deposit(item_deposit_action)
      content = item_deposit_action.content
      lock = open_version(druid: item_deposit_action.druid) || content.lock
      content.update!(lock:, **ocr_settings(item_deposit_action))
      content.start_staging!(user:, accession: true, notify: false, staging_location: Settings.assembly_location)
    rescue StandardError => e
      handle_deposit_error(e, item_deposit_action:)
    end

    # The description of an already open version is left as is.
    # @return [String, nil] the lock of the object with the opened version, if a version was opened
    def open_version(druid:)
      return if statuses[druid].open?

      Sdr::VersionService.open(druid:, description: version_description, opening_user_name: user.sunetid).lock
    end

    def ocr_settings(item_deposit_action)
      if MultiItemDepositAction::OCR_CONTENT_TYPES.include?(item_deposit_action.content_type)
        multi_item_deposit_action.slice(:perform_ocr, :ocr_languages).symbolize_keys
      else
        { perform_ocr: false, ocr_languages: [] }
      end
    end

    def handle_deposit_error(error, item_deposit_action:)
      Rails.logger.error(error.full_message)
      Honeybadger.notify(error)
      item_deposit_action.update!(deposit_errors: [message(:errors, :deposit_failed)])
    end

    # Returns the user to the deposit step, since checking fails before anything is deposited.
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
        allowed_to?(:update?, cocina_object, with: ObjectPolicy, context: { user: })
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
      I18n.t(key, scope: [:multi_item_deposit, :deposit, kind])
    end
  end
end
