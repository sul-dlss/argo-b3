# frozen_string_literal: true

# A user's opt-out of the emails of one kind of Notification. Every kind of email is on until the user opts out of
# it on the Email settings tab; toasts and the list of recent notifications are always delivered.
class EmailOptOut < ApplicationRecord
  # The email switches, in the order the Email settings tab lists them. Each Notifier that emails names the switch
  # covering its emails with ApplicationNotifier.email_notifier_kind.
  NOTIFIER_KINDS = %w[
    file_check_finished
    multi_item_deposit_settled
    deposit_failed
    bulk_action_object_deposits_settled_with_errors
    deposit_complete
  ].freeze

  belongs_to :user

  validates :notifier_kind, inclusion: { in: NOTIFIER_KINDS }
end
