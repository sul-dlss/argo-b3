# frozen_string_literal: true

# Serializer for ApplicationForm objects to be used with ActiveJob.
class FormSerializer < ActiveJob::Serializers::ObjectSerializer
  # Serializers for forms that cannot be serialized by FormSerializer alone.
  # These take precedence over FormSerializer.
  def self.form_serializers
    [ItemsRegistrationFormSerializer]
  end

  # ActiveJob performs its own serializer lookup when serializing job arguments, but its lookup is
  # only available once ActiveJob::Arguments has been loaded. Use this when serializing a form
  # outside of a job (e.g., FormValidationAction).
  # @param form [ApplicationForm] the form to be serialized
  # @return [Class] the serializer for the form
  def self.for(form)
    form_serializers.find { |form_serializer| form_serializer.serialize?(form) } || self
  end

  # Converts an object to a simpler representative using supported object types.
  # The recommended representative is a Hash with a specific key. Keys can be of basic types only.
  # You should call `super` to add the custom serializer type to the hash.
  def serialize(form)
    super(attributes: serializable_attributes(form), class: form.class)
  end

  # Converts serialized value into a proper object.
  def deserialize(hash)
    indifferent_hash = hash.with_indifferent_access
    # actual class is a subclass of ApplicationForm.
    actual_class = indifferent_hash[:class].then do |klass_param|
      klass_param.is_a?(String) ? klass_param.constantize : klass_param
    end
    actual_class.new(indifferent_hash[:attributes])
  end

  # Checks if an argument should be serialized by this serializer.
  def klass
    ApplicationForm
  end

  private

  # Override in subclasses for forms that have attributes that cannot be serialized as-is.
  def serializable_attributes(form)
    form.attributes
  end
end
