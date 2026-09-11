# frozen_string_literal: true

module Edit
  # Component for rendering edit form for access settings, including embargo
  class AccessAndEmbargoComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form
  end
end
