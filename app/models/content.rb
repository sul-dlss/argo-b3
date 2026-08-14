# frozen_string_literal: true

# Model for the structure (content) of an object
class Content < ApplicationRecord
  has_many :content_file_sets, -> { order(:position) }, inverse_of: :content, dependent: :destroy
  has_many :content_files, through: :content_file_sets
  has_many :content_file_binaries, inverse_of: :content, dependent: :destroy
end
