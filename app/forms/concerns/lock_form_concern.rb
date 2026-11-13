# frozen_string_literal: true

# Concern for edit forms that detect that the object was changed by someone else since the form was loaded.
module LockFormConcern
  extend ActiveSupport::Concern
  include EditCocinaObjectFormConcern

  included do
    # The lock of the Cocina object when the edit page was loaded, submitted back with the form.
    attribute :lock, :string
    form_only_attributes :lock
  end

  class_methods do
    # The lock comes only from the submission, so that a missing lock is stale.
    def from_submission(cocina_object, version_service:, params:)
      super(cocina_object, version_service:, params: params.reverse_merge(lock: nil))
    end
  end

  # The lock changes whenever the object is updated, so a different (or missing) lock means it changed since loading.
  def stale?
    lock != previous_cocina_object.lock
  end

  private

  def model_attrs_for(cocina_object)
    super.merge(lock: cocina_object.lock)
  end
end
