# frozen_string_literal: true

# Validates that an attribute is an existing path within one of the configured mount locations.
# Blank values are skipped; combine with presence: true to require a path.
class MountPathValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return record.errors.add(attribute, I18n.t('errors.mount_path.not_found')) unless File.exist?(value)
    return if within_mount_location?(value)

    record.errors.add(attribute, I18n.t('errors.mount_path.not_in_mount_location'))
  end

  private

  # Resolves symlinks and relative segments so that the path must be a true descendant of a mount location.
  def within_mount_location?(path)
    real_path = Pathname.new(path).realpath
    mount_locations.any? { |location| real_path.ascend.drop(1).include?(location) }
  end

  def mount_locations
    Settings.mount_locations.filter_map { |location| Pathname.new(location).realpath if File.exist?(location) }
  end
end
