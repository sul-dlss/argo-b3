# frozen_string_literal: true

module Edit
  # Component for rendering the fields shared by the forms for registering and editing an APO
  # The form's object must include TitleFormConcern and CocinaModels::AccessConcern, and have an agreement_druid
  # attribute.
  class ApoFieldsComponent < ApplicationComponent
    # @param agreement_options [Array<Array(String, String)>] the title and druid of each selectable agreement
    def initialize(form:, agreement_options:)
      @form = form
      @agreement_options = agreement_options
      super()
    end

    attr_reader :form, :agreement_options
  end
end
