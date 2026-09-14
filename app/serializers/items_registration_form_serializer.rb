# frozen_string_literal: true

# Serializer for ItemsRegistrationForm objects to be used with ActiveJob.
# An uploaded file cannot be serialized, so the uploaded CSV file is normalized to a CSV string
# in the csv attribute and the csv_file attribute is dropped.
class ItemsRegistrationFormSerializer < FormSerializer
  # Checks if an argument should be serialized by this serializer.
  def klass
    ItemsRegistrationForm
  end

  private

  def serializable_attributes(form)
    form.attributes.except('csv_file').tap do |attributes|
      # When reserializing an already serialized form, csv_file is nil and csv is retained.
      attributes['csv'] = CsvUpload::Normalizer.read(form.csv_file.path) if form.csv_file.present?
    end
  end
end
