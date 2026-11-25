# frozen_string_literal: true

# Model for an Argo user.
class User < ApplicationRecord
  has_many :bulk_actions, dependent: :destroy
  has_many :multi_item_deposit_actions, dependent: :destroy
  has_many :pinned_objects, dependent: :destroy
  has_many :pinned_searches, dependent: :destroy
  has_many :pinned_tags, dependent: :destroy
  has_many :tracked_deposits, dependent: :destroy
  has_many :email_opt_outs, dependent: :delete_all
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: 'Noticed::Notification'

  EMAIL_SUFFIX = '@stanford.edu'

  def sunetid
    email_address.delete_suffix(EMAIL_SUFFIX)
  end

  # @param notifier_kind [String] one of EmailOptOut::NOTIFIER_KINDS
  # @return [Boolean] whether the user gets that kind of Notification email (they haven't opted out of it)
  def email_on?(notifier_kind)
    !email_opt_outs.exists?(notifier_kind:)
  end
end
