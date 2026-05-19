# frozen_string_literal: true

module BulkActions
  # Form for manage content type bulk action.
  class ManageContentTypeForm < BasicForm
    attribute :change_content_type, :boolean, default: true
    attribute :new_content_type, :string
    attribute :change_resource_type, :boolean, default: false
    attribute :current_resource_type, :string
    attribute :new_resource_type, :string
    attribute :change_viewing_direction, :boolean, default: false
    attribute :viewing_direction, :string
  end
end
