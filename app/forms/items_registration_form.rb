# frozen_string_literal: true

# Form object for registering multiple Items (DROs)
class ItemsRegistrationForm < ApplicationForm
  include PermittedParamsConcern
  include PrevalidationConcern
  include CocinaModels::AccessConcern
  include CocinaModels::ContentTypeConcern
  include CocinaModels::ApoConcern
  include CocinaModels::EmbargoConcern
  include EmbargoFormConcern

  has_many :item_registrations, class_name: 'ItemRegistrationForm'

  before_validation :remove_blank_item_registrations
  validate :item_registrations_presence

  def initialize(attributes = {})
    super
    derive_with_embargo
  end

  private

  # Discards item registrations left blank by the user, unless every one of them is blank
  # (in which case item_registrations_presence should report the error instead).
  def remove_blank_item_registrations
    blank_item_registrations = item_registrations.select(&:empty?)
    return if blank_item_registrations.empty? || blank_item_registrations.size == item_registrations.size

    present_item_registrations = item_registrations.to_a - blank_item_registrations
    item_registrations.clear
    present_item_registrations.each { |item_registration| item_registrations.push(item_registration) }
  end

  def item_registrations_presence
    return if item_registrations.to_a.any? { |item_registration| !item_registration.empty? }

    errors.add(:item_registrations, I18n.t('edit.multiple_items.validations.no_items'))
  end
end
