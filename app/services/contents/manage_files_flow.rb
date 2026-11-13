# frozen_string_literal: true

module Contents
  # The steps of managing files: item details (except for agreements), add and edit files, structure files, and
  # deposit. The current step is saved with the mutable Content, along with the item details chosen so far.
  class ManageFilesFlow
    STEPS = Content.steps.keys.freeze

    # The steps with the fields of attributes that are not item details.
    STEPS_BY_ERROR_ATTRIBUTE = { content: 'structure', version_description: 'deposit' }.freeze

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

    # Saves the item details and moves to the next step. Leaving add and edit files structures the files, or
    # appends the files that are not in a resource to the existing resources.
    # Only call once current_step_complete? is true.
    # @param form [ContentsItemForm]
    def next!(form)
      leaving_step = current_step
      form.save_item_details!(step: step_at(1))
      start_structuring! if leaving_step == 'files'
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
      form.save_item_details!(step: step_at(-1))
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

    private

    attr_reader :content

    def step_at(offset)
      steps.fetch((steps.index(current_step) + offset).clamp(0, steps.size - 1))
    end

    def start_structuring!
      if content.content_file_sets.none?
        content.start_structuring!(append: false)
      elsif content.content_file_binaries.unassociated.exists?
        content.start_structuring!(append: true)
      end
    end
  end
end
