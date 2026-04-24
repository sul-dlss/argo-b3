class CocinaDescriptionEditorSchema < RubyLLM::Schema
  string :cocina_description_json, required: false,
                                   description: 'The updated Cocina Description JSON after applying the librarian\'s requested changes.'
  string :additional_questions, required: false,
                                description: 'Any additional questions you have for the librarian to clarify the requested changes or ensure the accuracy of the updated Cocina Description hash.'
end
