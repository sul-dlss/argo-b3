# frozen_string_literal: true

# Serializer for the validation errors of ApplicationForm objects.
#
# FormSerializer round-trips a form's attributes but not its errors. This serializer captures the errors
# produced by a validation so that they can be re-applied to a form deserialized later, without re-validating.
# The serialized structure mirrors ApplicationForm#attributes: nested association errors are keyed by
# "#{association_name}_attributes".
class FormErrorsSerializer
  # Raised when an error option would not round trip through jsonb, which would result in an incorrect error message.
  class UnserializableOptionError < StandardError; end

  # Types that survive a round trip through jsonb unchanged.
  JSON_PRIMITIVES = [String, Symbol, Numeric, TrueClass, FalseClass, NilClass].freeze

  class << self
    # @param form [ApplicationForm] a form that has been validated
    # @return [Hash] the form's errors, including the errors of any nested forms
    def serialize(form)
      { 'errors' => serialize_errors(form) }.tap do |serialized|
        form.class.associations.each do |name, association|
          nested_form = form.public_send(name)
          next if nested_form.nil?

          serialized["#{name}_attributes"] = case association[:type]
                                             when :has_one then serialize(nested_form)
                                             when :has_many then nested_form.map { |nested| serialize(nested) }
                                             end
        end
      end
    end

    # Re-applies serialized errors to a form and marks it (and any nested forms) as prevalidated.
    # @param form [ApplicationForm] the form to apply the errors to
    # @param error_data [Hash] errors as serialized by .serialize
    # @return [ApplicationForm] the form, with errors applied
    # @raise [ArgumentError] if the form (or one of its nested forms) does not include PrevalidationConcern
    def deserialize(form:, error_data:)
      check_prevalidatable!(form)

      indifferent_error_data = error_data.with_indifferent_access

      deserialize_errors(form, indifferent_error_data[:errors])
      form.prevalidated!

      form.class.associations.each do |name, association|
        nested_form = form.public_send(name)
        nested_error_data = indifferent_error_data["#{name}_attributes"]
        next if nested_form.nil? || nested_error_data.nil?

        deserialize_nested(nested_form, nested_error_data, association[:type])
      end

      form
    end

    private

    # @raise [ArgumentError] if the form cannot have its errors applied without validating
    def check_prevalidatable!(form)
      return if form.is_a?(PrevalidationConcern)

      raise ArgumentError, "#{form.class} must include PrevalidationConcern to have its errors deserialized"
    end

    def serialize_errors(form)
      form.errors.map do |error|
        {
          'attribute' => error.attribute.to_s,
          'type' => error.type.to_s,
          'type_class' => error.type.class.name,
          'options' => serialize_options(error)
        }
      end
    end

    def serialize_options(error)
      error.options.each_with_object({}) do |(key, value), options|
        check_serializable_option!(error:, key:, value:)
        options[key.to_s] = value
      end
    end

    def json_primitive?(value)
      case value
      when Array then value.all? { |item| json_primitive?(item) }
      when Hash then value.all? { |key, item| json_primitive?(key) && json_primitive?(item) }
      else JSON_PRIMITIVES.any? { |primitive| value.is_a?(primitive) }
      end
    end

    # An option that is not a JSON primitive will not round trip through jsonb, which would result in an incorrect
    # error message. Raise rather than serialize the option and render the wrong message later.
    # @raise [UnserializableOptionError] if the option value is not a JSON primitive
    def check_serializable_option!(error:, key:, value:)
      return if json_primitive?(value)

      raise UnserializableOptionError,
            "#{value.class} option #{key} on #{error.attribute} cannot be serialized without loss"
    end

    def deserialize_errors(form, serialized_errors)
      Array(serialized_errors).each do |serialized_error|
        type = serialized_error[:type]
        type = type.to_sym if serialized_error[:type_class] == 'Symbol'
        options = serialized_error[:options].to_h.symbolize_keys

        form.errors.add(serialized_error[:attribute].to_sym, type, **options)
      end
    end

    def deserialize_nested(nested_form, nested_error_data, association_type)
      case association_type
      when :has_one
        deserialize(form: nested_form, error_data: nested_error_data)
      when :has_many
        nested_form.each_with_index do |form, index|
          nested_error_datum = nested_error_data[index]
          deserialize(form:, error_data: nested_error_datum) if nested_error_datum
        end
      end
    end
  end
end
