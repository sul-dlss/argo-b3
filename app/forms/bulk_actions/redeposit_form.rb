# frozen_string_literal: true

module BulkActions
  # Form for the redeposit bulk action.
  class RedepositForm < BasicForm
    # Applied to objects whose version is opened, or whose open version has no description.
    attribute :version_description, :string
    normalizes_whitespace :version_description
    validates :version_description, presence: true
  end
end
