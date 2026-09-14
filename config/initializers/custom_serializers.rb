# frozen_string_literal: true

# Note that ActiveJob::Serializers indexes serializers by their exact klass, so
# ItemsRegistrationFormSerializer is used for ItemsRegistrationForm and FormSerializer for every
# other ApplicationForm.
Rails.application.config.active_job.custom_serializers.push(FormSerializer, *FormSerializer.form_serializers)
