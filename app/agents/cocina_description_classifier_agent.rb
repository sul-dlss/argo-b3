class CocinaDescriptionClassifierAgent < RubyLLM::Agent
  model 'gemini-flash-latest'

  # Change `Chat` to your app's chat model for Rails persistence.
  # Remove this line to skip persistence and use plain RubyLLM chats.
  # chat_model Chat
  instructions
  schema do
    string :field,
           enum: %w[title contributor event form language note identifier subject access geographic
                    relatedResource adminMetadata marcEncodedData valueAt none]
  end
end
