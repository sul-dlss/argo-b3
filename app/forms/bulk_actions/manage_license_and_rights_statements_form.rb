# frozen_string_literal: true

module BulkActions
  # Form for manage license and rights statements bulk action.
  class ManageLicenseAndRightsStatementsForm < BasicForm
    attribute :use_and_reproduction_statement, :string
    attribute :use_and_reproduction_statement_action, :string, default: 'no_change'

    attribute :copyright, :string
    attribute :copyright_action, :string, default: 'no_change'

    attribute :license, :string
    attribute :license_action, :string, default: 'no_change'
  end
end
