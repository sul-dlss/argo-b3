# frozen_string_literal: true

module BulkActions
  # Job to register objects from a CSV file
  class RegisterJob < BaseJob
    HEADERS = ['Druid', 'Barcode', 'Folio Instance HRID', 'Source Id', 'Label'].freeze

    def perform(bulk_action:, csv_file:, **register_params)
      @csv_file = csv_file
      @register_params = register_params
      super
    end

    def perform_bulk_action
      convert_results.each.with_index do |convert_result, index|
        Item.new(index:, job: self, convert_result:).perform
      rescue StandardError => e
        failure!(message: "Failed #{e.class} #{e.message}", index:)
      end
    end

    def success!(message:, index:, druid: nil)
      bulk_action.increment(:druid_count_success).save
      log(log_msg(message:, index:, druid:))
    end

    def failure!(message:, index:, druid: nil)
      bulk_action.increment(:druid_count_fail).save
      log(log_msg(message:, index:, druid:))
    end

    def log_msg(message:, index:, druid: nil)
      msg = " - line #{index} - #{message}"
      msg += " for #{druid}" if druid
      msg
    end

    def druid_count
      convert_results.length
    end

    def convert_results
      @convert_results ||= RegistrationCsvConverter.convert(csv_string: @csv_file, params: register_params)
    end

    def export_file
      @export_file ||= CSV.open(bulk_action.export_filepath, 'wb', write_headers: true, headers: HEADERS)
    end

    attr_reader :register_params

    # Register a single object from the CSV
    class Item < JobItem
      def initialize(convert_result:, **args)
        @convert_result = convert_result
        super(druid: nil, **args)
      end

      attr_reader :convert_result

      def perform
        return failure!(message: convert_result.failure.message) if convert_result.failure?

        # After registration, set druid and cocina_object so that logging, etc. works as expected.
        @cocina_object = Sdr::Repository.register(user_name: user, **convert_result.value!)
        @druid = cocina_object.externalIdentifier

        success!(message: 'Registration successful')
        export_file << row
      end

      def row
        [
          DruidSupport.bare_druid_from(cocina_object.externalIdentifier),
          cocina_object.identification.barcode,
          cocina_object.identification.catalogLinks.first&.catalogRecordId,
          cocina_object.identification.sourceId,
          cocina_object.label
        ]
      end

      def success!(message:)
        job.success!(druid:, message:, index:)
      end

      def failure!(message:)
        job.failure!(druid:, message:, index:)
      end
    end
  end
end
