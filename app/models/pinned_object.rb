# frozen_string_literal: true

# Model for a pinned object
class PinnedObject < ApplicationRecord
  belongs_to :user

  validates :druid, presence: true, druid: true
end
