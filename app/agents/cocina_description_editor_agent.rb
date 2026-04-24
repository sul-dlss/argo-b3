class CocinaDescriptionEditorAgent < RubyLLM::Agent
  # model 'gemini-3.1-pro-preview'
  model 'gemini-flash-latest'
  chat_model Chat
  inputs :original_cocina_description_hash
  instructions do
    [
      prompt('instructions'),
      prompt('common'),
      prompt('title')
    ].join("\n\n")
  end
  # instructions cocina_description_hash: -> { cocina_description_hash }, property: -> { property }
  # tools CocinaDescriptionValidatorTool
  tools do
    CocinaDescriptionValidatorTool.new(original_cocina_description_hash:)
  end
  # params generationConfig: { responseMimeType: 'application/json' }
  # schema({ name: 'Cocina Description Schema', schema: CocinaDescriptionSchemaGenerator.call })
  schema CocinaDescriptionEditorSchema
  temperature 0.0
end
