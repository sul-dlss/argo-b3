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

    def job_params
      {
        change_copyright: change?(:copyright),
        copyright: updated_value(:copyright),
        change_license: change?(:license),
        license: updated_value(:license),
        change_use_and_reproduction_statement: change?(:use_and_reproduction_statement),
        use_and_reproduction_statement: updated_value(:use_and_reproduction_statement)
      }
    end

    private

    def change?(attribute_name)
      %w[update remove].include?(public_send(:"#{attribute_name}_action"))
    end

    # @return [String, nil] the attribute's value when its action is update
    def updated_value(attribute_name)
      public_send(attribute_name) if public_send(:"#{attribute_name}_action") == 'update'
    end
  end
end
