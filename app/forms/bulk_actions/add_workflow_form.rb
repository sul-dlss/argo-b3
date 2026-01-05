# frozen_string_literal: true

module BulkActions
  # Form for add workflow bulk action.
  class AddWorkflowForm < BasicForm
    attribute :workflow_name, :string
  end
end
