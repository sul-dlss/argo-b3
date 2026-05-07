# frozen_string_literal: true

# Agent that creates a structural representation of a book.
class BookStructuralAgent < RubyLLM::Agent
  model 'gemini-3.1-flash-lite-preview', provider: Rails.env.production? ? :vertexai : :gemini
  chat_model StructuralChat
  temperature 1.0 # With Gemini 3+, recommended to keep >= 1.0
  # thinking effort: :medium
  instructions
  schema do
    string :structured_json_representation,
           description: 'A JSON representation of the structural metadata for a book.', required: false
    string :clarifications, description: 'Any questions or clarifications the agent has for the user.'
  end
end
