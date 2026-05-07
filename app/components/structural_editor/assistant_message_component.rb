# frozen_string_literal: true

class StructuralEditor::AssistantMessageComponent < ApplicationComponent
  def initialize(message:)
    @message = message
    super()
  end

  attr_reader :message

  def text
    message.content_raw['clarifications'].presence || 'Updated Cocina structural metadata.'
  end
end
