# frozen_string_literal: true

module BulkActions
  # Form for open version bulk action
  class OpenVersionForm < BasicForm
    attribute :version_description, :string
    validates :version_description, presence: true
  end
end
