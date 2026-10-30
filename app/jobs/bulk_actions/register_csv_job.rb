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
        message = if convert_result.failure?
                    convert_result.failure.message
                  elsif !create_allowed?
                    'Not authorized to register with this APO and collections'
                  end
        return true unless message

        failure!(message:)
        false
      end

      def create_allowed?
        request_cocina_object = convert_result.value![:request_cocina_object]
        dro = CocinaModels::Dro.new(apo_druid: request_cocina_object.administrative.hasAdminPolicy,
                                    collection_druids: Array(request_cocina_object.structural&.isMemberOf))
        allowed_to?(:create?, dro, with: ItemPolicy)
      end

      def register
        Sdr::Repository.register(user_name: user_id, **convert_result.value!)
      end
    end
  end
end
