# frozen_string_literal: true

# Model for an Argo user.
class User < ApplicationRecord
  has_many :bulk_actions, dependent: :destroy
end
