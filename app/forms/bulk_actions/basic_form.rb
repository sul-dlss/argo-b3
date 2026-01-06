# frozen_string_literal: true

module BulkActions
  # Form object that only includes the basic attributes.
  # This can be used by itself or as a superclass for more complex forms.
  class BasicForm < ApplicationForm
    attribute :source, :string, default: 'druids'
    attribute :druid_list, :string
    validates :druid_list, presence: true, if: -> { source == 'druids' }
    attribute :description, :string

    # Only applies to some bulk actions.
    # For those bulk actions, with_close_version to true for BulkActions::FormComponent.
    attribute :close_version, :boolean, default: true
  end
end
