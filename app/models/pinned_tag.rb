# frozen_string_literal: true

# Model for a pinned tag
class PinnedTag < ApplicationRecord
  belongs_to :user

  validates :tag, presence: true
end
