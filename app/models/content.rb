# frozen_string_literal: true

# Model for the structure (content) of an object
class Content < ApplicationRecord
  has_many :content_file_sets, -> { order(:position) }, inverse_of: :content, dependent: :destroy
end
