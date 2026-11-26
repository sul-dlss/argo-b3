# frozen_string_literal: true

# Form object for a mount path
class MountForm < ApplicationForm
  attribute :path, :string
  normalizes_path :path
  validates :path, presence: true, mount_path: true
end
