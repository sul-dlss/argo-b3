# frozen_string_literal: true

# Model for an Argo user.
class User < ApplicationRecord
  has_many :bulk_actions, dependent: :destroy
  has_many :multi_item_deposit_actions, dependent: :destroy
  has_many :pinned_objects, dependent: :destroy
  has_many :pinned_searches, dependent: :destroy
  has_many :pinned_tags, dependent: :destroy
  has_many :tracked_deposits, dependent: :destroy
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: 'Noticed::Notification'

  EMAIL_SUFFIX = '@stanford.edu'

  def sunetid
    email_address.delete_suffix(EMAIL_SUFFIX)
  end
end
