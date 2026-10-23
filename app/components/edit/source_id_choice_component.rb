# frozen_string_literal: true

module Edit
  # Component for rendering edit form for source ID choice
  # The form's object must include CocinaModels::SourceIdConcern and provide source_id_choice and source_id_prefix.
  class SourceIdChoiceComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form
  end
end
