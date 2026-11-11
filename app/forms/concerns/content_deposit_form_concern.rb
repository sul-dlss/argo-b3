# frozen_string_literal: true

# Concern for a form that edits, and may deposit, an object with content (files): depositing requires the
# object's structure to be valid for its content type and its mutable Content to have no unsaved changes.
# Validate with the :deposit context when depositing.
#
# Requires previous_cocina_object and mutated_cocina_object, as provided by CocinaModels::Dro.
module ContentDepositFormConcern
  extend ActiveSupport::Concern

  included do
    # Only depositing requires the structure to be valid for the content type.
    validate :structure_valid_for_content_type, on: :deposit
    # Depositing deposits the structure as last staged, so it would discard unsaved changes.
    validate :content_is_saved, on: :deposit

    # The object's mutable Content, if any; not an attribute so that setting it does not make the form dirty.
    attr_accessor :content
  end

  private

  # Keeps the content on the object's current lock, so that editing continues on it.
  def rebase_content_lock
    content.update!(lock: previous_cocina_object.lock) if content&.persisted?
  end

  # Depositing deposits the cocina structure, not the mutable Content, so the immutable Content is validated
  # against the object as edited (since the form may change its content type and access).
  # Skipped when the edited object cannot be built, since the invalid fields have their own errors.
  def structure_valid_for_content_type
    immutable_content = Contents::Builder.find_or_create(cocina_object: previous_cocina_object)
    return if Contents::Validator.call(content: immutable_content, cocina_object: mutated_cocina_object,
                                       saved_access: previous_cocina_object.access).valid?

    errors.add(:content, I18n.t('edit.items.fields.content.validations.invalid'))
  rescue Cocina::Models::ValidationError
    nil
  end

  def content_is_saved
    return unless Contents::UnsavedChanges.call(content:, cocina_object: previous_cocina_object)

    errors.add(:content, I18n.t('edit.items.fields.content.validations.unsaved'))
  end
end
