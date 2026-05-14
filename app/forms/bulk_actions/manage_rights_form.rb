# frozen_string_literal: true

module BulkActions
  # Form for manage rights bulk action.
  class ManageRightsForm < BasicForm
    attribute :rights, :string, default: 'world'
    attribute :view, :string
    attribute :download, :string
    attribute :location, :string
  end
end
