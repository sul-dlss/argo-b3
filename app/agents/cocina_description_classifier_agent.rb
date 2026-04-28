# frozen_string_literal: true

class CocinaDescriptionClassifierAgent < RubyLLM::Agent
  # model 'gemini-flash-latest'
  model 'gemini-3-flash-preview', provider: Rails.env.production? ? :vertexai : :gemini

  instructions
  schema do
    string :field,
           enum: %w[title contributor event form language note identifier subject access geographic
                    relatedResource adminMetadata marcEncodedData valueAt none]
  end
end
