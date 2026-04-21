# frozen_string_literal: true

# Agent that updates a Cocina description based on the user's request.
class CocinaDescriptionEditorAgent < RubyLLM::Agent
  # model 'gemini-3-flash-preview', provider: Rails.env.production? ? :vertexai : :gemini
  model 'gemini-3.1-flash-lite-preview', provider: Rails.env.production? ? :vertexai : :gemini
  chat_model Chat
  tools UrlFetchTool, ModelTool
  params generationConfig: { responseMimeType: 'application/json' }
  temperature 1.0 # With Gemini 3+, recommended to keep >= 1.0
  thinking effort: :medium
end
