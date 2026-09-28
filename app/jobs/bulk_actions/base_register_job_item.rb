# frozen_string_literal: true

module BulkActions
  # Superclass for registering a single object in a bulk action job.
  # Subclasses must implement the `#register` method.
  class BaseRegisterJobItem < BaseJobItem
    def initialize(registration:, registration_report_csv:, **args)
      @registration = registration
      @registration_report_csv = registration_report_csv
      super(druid: nil, **args)
    end

    attr_reader :registration, :registration_report_csv

    def perform
      return unless valid?

      # After registration, set druid and cocina_object so that logging, etc. works as expected.
      @cocina_object = register
      @druid = cocina_object.externalIdentifier

      success!(message: 'Registration successful')
      registration_report_csv << row
    end

    # Subclasses may override to report a failure before registration is attempted.
    def valid?
      true
    end

    # Subclasses must implement.
    # @return [Cocina::Models::DROWithMetadata] the registered object
    def register
      raise NotImplementedError
    end

    def row # rubocop:disable Metrics/AbcSize
      [
        DruidSupport.bare_druid_from(cocina_object.externalIdentifier),
        cocina_object.identification.barcode,
        cocina_object.identification.catalogLinks.first&.catalogRecordId,
        cocina_object.identification.sourceId,
        Cocina::Models::Builders::TitleBuilder.build(cocina_object.description.title)
      ]
    end

    def success!(message:)
      job.success!(druid:, message: "Success: #{message}", index:)
    end

    def failure!(message:)
      job.failure!(druid:, message: "Error: #{message}", index:)
    end
  end
end
