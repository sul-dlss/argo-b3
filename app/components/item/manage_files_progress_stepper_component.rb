# frozen_string_literal: true

module Item
  # Renders the steps of managing files (see Contents::ManageFilesFlow) with their statuses: the steps before the
  # current step are completed and the steps after it are pending.
  class ManageFilesProgressStepperComponent < ApplicationComponent
    # @param manage_files_flow [Contents::ManageFilesFlow]
    def initialize(manage_files_flow:)
      @manage_files_flow = manage_files_flow
      super()
    end

    def call
      render Elements::ProgressStepperComponent.new(label: t('edit.contents.steps.label'), steps:, classes: 'mb-4')
    end

    private

    attr_reader :manage_files_flow

    def steps
      current_index = manage_files_flow.steps.index(manage_files_flow.current_step)
      manage_files_flow.steps.map.with_index do |step, index|
        { label: t("edit.contents.steps.#{step}"), status: status_for(index:, current_index:) }
      end
    end

    def status_for(index:, current_index:)
      return :completed if index < current_index
      return :in_progress if index == current_index

      :pending
    end
  end
end
