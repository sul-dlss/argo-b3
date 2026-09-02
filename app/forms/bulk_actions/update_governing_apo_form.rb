# frozen_string_literal: true

module BulkActions
  # Form object for update governing APO bulk action.
  class UpdateGoverningApoForm < BasicForm
    attribute :new_apo_id, :string
    validates :new_apo_id, presence: true
  end
end
