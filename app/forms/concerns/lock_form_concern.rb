# frozen_string_literal: true

# Concern for edit forms that detect that the object was changed by someone else since the form was loaded.
module LockFormConcern
  extend ActiveSupport::Concern

  included do
    # The lock of the Cocina object when the edit page was loaded, submitted back to detect that the object
    # was changed by someone else in the meantime. It is not part of the Cocina object.
    attribute :lock, :string
  end

  private

  def model_attrs_for(cocina_object)
    super.merge(lock: cocina_object.lock)
  end
end
