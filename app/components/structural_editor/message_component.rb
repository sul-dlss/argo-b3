# frozen_string_literal: true

class StructuralEditor::MessageComponent < ApplicationComponent
  def initialize(message:)
    @message = message
    super()
  end

  attr_reader :message

  def call
    component_class = case message.role
                      when 'assistant'
                        StructuralEditor::AssistantMessageComponent
                      else
                        Chat::BaseMessageComponent
                      end
    render component_class.new(message:)
  end
end
