# frozen_string_literal: true

module BulkActions
  # Form object that only includes the basic attributes.
  # This can be used by itself or as a superclass for more complex forms.
  class BasicForm < ApplicationForm
    attribute :source, :string, default: 'druids'
    attribute :druid_list, :string
    validates :druid_list, presence: true, if: -> { source == 'druids' }
    attribute :description, :string

    # Only offered by bulk actions configured with close_version.
    attribute :close_version, :boolean, default: true

    # Subclasses may override; the controller adds druids and, if configured, close_version.
    # @return [Hash] the job parameters from the form's own attributes
    def job_params
      attributes.symbolize_keys.except(:source, :druid_list, :description, :close_version)
    end
  end
end
