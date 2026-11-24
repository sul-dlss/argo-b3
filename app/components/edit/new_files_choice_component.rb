# frozen_string_literal: true

module Edit
  # Component for asking whether to append files that are not in a resource to the structure or to rebuild it.
  # It has no form object: the choice is submitted as new_files[structure] with the step's item form
  # (see contents/files).
  class NewFilesChoiceComponent < ApplicationComponent
    # The choice is kept when the frame reloads (see new-files-choice in contents/files).
    def input_data
      { new_files_choice_target: 'radio', action: 'change->new-files-choice#remember' }
    end
  end
end
