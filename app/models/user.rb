# frozen_string_literal: true

# Model for an Argo user.
class User < ApplicationRecord
  has_many :bulk_actions, dependent: :destroy

  EMAIL_SUFFIX = '@stanford.edu'

  def sunetid
    email_address.delete_suffix(EMAIL_SUFFIX)
  end
end
