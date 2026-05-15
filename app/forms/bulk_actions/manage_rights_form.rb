# frozen_string_literal: true

module BulkActions
  # Form for manage rights bulk action.
  class ManageRightsForm < BasicForm
    attribute :view, :string, default: 'world'
    attribute :download, :string, default: 'world'
    attribute :location, :string, default: nil
  end
end
