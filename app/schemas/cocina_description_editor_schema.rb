class CocinaDescriptionEditorSchema < RubyLLM::Schema
  string :cocinaDescriptionJson, required: false,
                                 description: 'The updated Cocina Description JSON after applying the librarian\'s requested changes.'
  string :additionalQuestions, required: false,
                               description: 'Any additional questions you have for the librarian to clarify the requested changes or ensure the accuracy of the updated Cocina Description hash.'
end
