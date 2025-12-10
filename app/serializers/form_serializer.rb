# frozen_string_literal: true

# Serializer for ApplicationForm objects to be used with ActiveJob.
class FormSerializer < ActiveJob::Serializers::ObjectSerializer
  # Converts an object to a simpler representative using supported object types.
  # The recommended representative is a Hash with a specific key. Keys can be of basic types only.
  # You should call `super` to add the custom serializer type to the hash.
  def serialize(form)
    super(attributes: form.attributes, class: form.class)
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
end
