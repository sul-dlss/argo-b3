# frozen_string_literal: true

class CocinaDescriptionEditorAgent < RubyLLM::Agent
  # model 'gemini-3.1-pro-preview'
  # model 'gemini-flash-latest'
  model 'gemini-3-flash-preview', provider: Rails.env.production? ? :vertexai : :gemini
  chat_model Chat
  # inputs :original_cocina_description_hash
  # instructions do
  #   [
  #     prompt('instructions'),
  #     prompt('common')
  #   ].join("\n\n")
  # end
  # NOTE: schema isn't working correctly with Gemini, so requesting a JSON response.
  # The response is described in the instructions.
  # JSON response doesn't work with tools, so validating response separately.
  # instructions cocina_description_hash: -> { cocina_description_hash }, property: -> { property }
  # tools CocinaDescriptionValidatorTool
  # tools do
  #   CocinaDescriptionValidatorTool.new(original_cocina_description_hash:)
  # end
  tools UrlFetchTool, ModelTool
  params generationConfig: { responseMimeType: 'application/json' }
  # schema({ name: 'Cocina Description Schema', schema: CocinaDescriptionSchemaGenerator.call })
  # schema CocinaDescriptionEditorSchema
  temperature 0.0
end
