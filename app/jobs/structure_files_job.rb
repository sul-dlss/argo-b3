# frozen_string_literal: true

# Job that structures the files of a mutable Content (into ContentFileSets and ContentFiles) with the populator
# selected for its content type, either replacing the existing resources or appending the unassociated files.
class StructureFilesJob < ApplicationJob
  queue_as :real_time

  # @param [Content] content
  # @param [Boolean] append whether to add the unassociated files to the existing resources rather than replacing them
  def perform(content:, append:)
    cocina_object = content.with_selected_access(Sdr::Repository.find(druid: content.druid))
    populator = select_populator(content:, cocina_object:)
    # A failure leaves the existing resources unchanged.
    ActiveRecord::Base.transaction do
      append ? populator.append(content:, cocina_object:) : populator.structure(content:, cocina_object:)
    end
    content.structuring_completed!
  rescue StandardError => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e, context: { druid: content.druid })
    content.reload.structuring_errored!
  end

  private

  def select_populator(content:, cocina_object:)
    Contents::PopulatorSelector.call(content:, cocina_object:,
                                     content_type: content.selected_content_type(cocina_object))
                               .actual_populator
  end
end
