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

    def job_params
      {
        current_resource_type: current_resource_type.presence,
        new_content_type: new_content_type.presence,
        new_resource_type: new_resource_type.presence,
        viewing_direction: viewing_direction.presence
      }
    end
  end
end
