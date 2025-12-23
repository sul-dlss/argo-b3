# frozen_string_literal: true

module BulkActions
  # Forn for manage release bulk action.
  class ManageReleaseForm < BasicForm
    attribute :to, :string
    attribute :release, :boolean, default: true
  end
end
