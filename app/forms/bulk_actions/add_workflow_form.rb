# frozen_string_literal: true

module BulkActions
  # Form for add workflow bulk action.
  class AddWorkflowForm < BasicForm
    WORKFLOWS = (Constants::WORKFLOWS - %w[accessionWF registrationWF]).freeze

    attribute :workflow_name, :string
  end
end
