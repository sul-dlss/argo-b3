# frozen_string_literal: true

module Edit
  # Component for asking, when depositing an Item, whether to keep the previous User Version on PURL.
  # The form's object must include NewUserVersionFormConcern.
  # The question is hidden and disabled while the Item is dark, also when the view access is changed to dark in the
  # same form (see new_user_version_controller.js).
  class NewUserVersionComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    # Behind feature_flags.new_user_version. The previous version of a first version is not deposited.
    def render?
      Settings.feature_flags.new_user_version && !form.object.initial_version?
    end

    def dark?
      !form.object.ask_new_user_version?
    end
  end
end
