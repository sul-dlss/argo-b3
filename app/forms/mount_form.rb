# frozen_string_literal: true

# Form object for a mount path
class MountForm < ApplicationForm
  attribute :path, :string
  validates :path, presence: true
  validate :path_exists, if: -> { errors[:path].empty? }
  validate :path_within_mount_location, if: -> { errors[:path].empty? }

  private

  def path_exists
    errors.add(:path, I18n.t('edit.items.fields.mount_path.validations.not_found')) unless File.exist?(path)
  end

  # Resolves symlinks and relative segments so that the path must be a true descendant of a mount location.
  def path_within_mount_location
    return if mount_locations.any? { |location| real_path.ascend.drop(1).include?(location) }

    errors.add(:path, I18n.t('edit.items.fields.mount_path.validations.not_in_mount_location'))
  end

  def real_path
    @real_path ||= Pathname.new(path).realpath
  end

  def mount_locations
    Settings.mount_locations.filter_map { |location| Pathname.new(location).realpath if File.exist?(location) }
  end
end
