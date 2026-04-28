# frozen_string_literal: true

class Editor::CocinaDescriptionCardComponent < ApplicationComponent
  def initialize(cocina_description_hash:)
    @cocina_description_hash = cocina_description_hash
    super()
  end

  private

  attr_reader :cocina_description_hash
end
