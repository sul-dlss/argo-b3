# frozen_string_literal: true

# Agent that determines the Cocina field that is being updated based on the user's request.
class CocinaDescriptionClassifierAgent < RubyLLM::Agent
  model 'gemini-3.1-flash-lite-preview', provider: Rails.env.production? ? :vertexai : :gemini

  instructions
  schema do
    string :field,
           enum: %w[title contributor event form language note identifier subject access geographic
                    relatedResource adminMetadata marcEncodedData valueAt none]
  end
  thinking effort: :low
  temperature 1.0 # With Gemini 3+, recommended to keep >= 1.0
end
