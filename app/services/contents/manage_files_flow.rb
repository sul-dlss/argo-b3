# frozen_string_literal: true

module Contents
  # The steps of managing files: item details (except for agreements), add and edit files, structure files, and
  # deposit. The current step is saved with the mutable Content, along with the item details chosen so far.
  # Entering managing files opens on a step chosen by where it is entered from (see #open_on!); moving within it
  # keeps the saved step.
  class ManageFilesFlow
    STEPS = Content.steps.keys.freeze

    # Where managing files can be entered from, as the step to open on: the first step (e.g., from registering, or
    # from "Save draft and edit files"), or structure files (from the status box).
    OPEN_ON_FIRST = 'first'
    OPEN_ON_STRUCTURE = 'structure'

    # The steps with the fields of attributes that are not item details.
    STEPS_BY_ERROR_ATTRIBUTE = { content: 'structure', version_description: 'deposit' }.freeze

    # Returns to the first step and clears the item details, e.g., once they are saved to the object.
    # @param content [Content] the mutable Content
    def self.reset!(content:)
      ItemDetails.new(content:).clear!(step: STEPS.first)
    end

    # Whether add and edit files asks how new files should be structured: appended to the existing resources, or
    # the resources rebuilt.
    # @param content [Content]
    def self.new_files_question?(content:)
      content.content_file_sets.exists? && content.content_file_binaries.unassociated.exists?
    end

    # @param content [Content] the mutable Content
    # @param agreement [Boolean] whether the object is an agreement, which has no item details to edit
    def initialize(content:, agreement:)
      @content = content
      @agreement = agreement
    end

    # @return [Array<String>] the steps, in order
    def steps
      @agreement ? STEPS - ['details'] : STEPS
    end

    # @return [String] the saved step, or the first step when the saved step is not one of the steps
    def current_step
      steps.include?(content.step) ? content.step : steps.first
    end

    def first_step?
      current_step == steps.first
    end

    def last_step?
      current_step == steps.last
    end

    def structure_step?
      current_step == 'structure'
    end

    # Saves the item details and moves to the next step. Leaving add and edit files structures the files, or, when
    # there are resources, appends the files that are not in a resource to them or rebuilds them, as the user chose
    # (see #new_files_question?).
    # Only call once current_step_complete? is true.
    # @param form [ContentsItemForm]
    # @param rebuild [Boolean] whether to replace the existing resources rather than append to them
    def next!(form, rebuild: false)
      leaving_step = current_step
      ItemDetails.new(content:).save!(form, step: step_at(1))
      start_structuring!(rebuild:) if leaving_step == 'files'
    end

    # @param form [ContentsItemForm]
    # @return [Boolean] false if the current step can't be left for the next: invalid item details or no files
    def current_step_complete?(form)
      case current_step
      when 'details' then form.item_details_valid?
      when 'files' then content.content_file_binaries.exists?
      else true
      end
    end

    # Saves the item details and moves to the previous step.
    # @param form [ContentsItemForm]
    def previous!(form)
      ItemDetails.new(content:).save!(form, step: step_at(-1))
    end

    # Moves to the step that entering managing files opens on. Opening on structure files opens on add and edit files
    # when there are no files, or when there are resources and files that are not in one, so that the user chooses
    # how to structure the new files; otherwise it structures the files when there are no resources. The step is kept
    # while the content is busy, since discovering or structuring needs the step it started on.
    # @param open_on [String] OPEN_ON_FIRST or OPEN_ON_STRUCTURE
    def open_on!(open_on)
      return if content.busy?

      case open_on
      when OPEN_ON_FIRST then content.update!(step: steps.first)
      when OPEN_ON_STRUCTURE then open_on_structure!
      end
    end

    # Moves to the step with the fields of the first error that depositing would find, if any.
    # @param form [ContentsItemForm]
    def go_to_deposit_errors!(form)
      go_to_first_error!(form.errors) unless form.valid?(:deposit)
    end

    # Moves to the step with the fields of the first error, e.g., after depositing failed validation.
    # @param errors [ActiveModel::Errors]
    def go_to_first_error!(errors)
      error_steps = errors.attribute_names.map { |attribute| STEPS_BY_ERROR_ATTRIBUTE.fetch(attribute, 'details') }
      step = steps.find { |candidate_step| error_steps.include?(candidate_step) }
      content.update!(step:) if step
    end

    # The result is shown once, so taking it clears it.
    # @return [String, nil] 'structured' or 'structuring_failed', or nil if there is no result to show
    def take_structuring_result!
      return unless content.structured? || content.structuring_failed?

      content.structuring_state.tap { content.structuring_result_shown! }
    end

    private

    attr_reader :content

    def step_at(offset)
      steps.fetch((steps.index(current_step) + offset).clamp(0, steps.size - 1))
    end

    def open_on_structure!
      if !content.content_file_binaries.exists? || self.class.new_files_question?(content:)
        return content.update!(step: 'files')
      end

      content.update!(step: 'structure')
      start_structuring!
    end

    def start_structuring!(rebuild: false)
      if rebuild || content.content_file_sets.none?
        content.start_structuring!(append: false)
      elsif content.content_file_binaries.unassociated.exists?
        content.start_structuring!(append: true)
      end
    end
  end
end
