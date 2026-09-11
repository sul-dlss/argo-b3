# frozen_string_literal: true

module BulkActions
  # Job to register objects from a CSV file
  class RegisterCsvJob < BaseRegisterJob
    def perform(bulk_action:, csv_file:, **register_params)
      @csv_file = csv_file
      @register_params = register_params
      super
    end

    def registrations
      @registrations ||= RegistrationCsvConverter.convert(csv_string: @csv_file, params: register_params)
    end

    # The header is line 1, so the first registration is line 2.
    def index_offset
      2
    end

    attr_reader :register_params

    # Register a single object from the CSV
    class JobItem < BaseRegisterJobItem
      alias convert_result registration

      def valid?
        return true unless convert_result.failure?

        failure!(message: convert_result.failure.message)
        false
      end

      def register
        Sdr::Repository.register(user_name: user_id, **convert_result.value!)
      end
    end
  end
end
