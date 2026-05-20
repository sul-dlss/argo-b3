# frozen_string_literal: true

module BulkActions
  # Job to update content type and optionally remap resource types
  class ManageContentTypeJob < ClosingDruidsJob
    def perform(bulk_action:, druids:, close_version: false, # rubocop:disable Metrics/ParameterLists
                new_content_type: nil,
                current_resource_type: nil, new_resource_type: nil,
                viewing_direction: nil)
      @current_resource_type = current_resource_type
      @new_content_type = new_content_type
      @new_resource_type = new_resource_type
      @viewing_direction = viewing_direction
      super
    end

    attr_reader :current_resource_type, :new_content_type, :new_resource_type, :viewing_direction

    # Update content type on a single item
    class JobItem < BaseJobItem
      delegate :current_resource_type, :new_content_type, :new_resource_type, :viewing_direction, to: :job

      def perform # rubocop:disable Metrics/AbcSize
        return unless check_update_ability?

        return failure!(message: "Object is a #{cocina_object.type} and cannot be updated") unless cocina_object.dro?

        update_cocina_model

        return failure!(message: cocina_model.errors.full_messages.join(', ')) unless cocina_model.valid?

        return success!(message: 'No changes made') unless cocina_model.changed? || resource_types_should_change?

        open_new_version_if_needed!(description: 'Updated content type')

        Sdr::Repository.update(cocina_object: build_updated_cocina_object,
                               user_name: user_id, description: 'Updated content type')
        close_version_if_needed!

        success!(message: 'Successfully updated content type')
      end

      private

      def build_updated_cocina_object
        model_mutated = CocinaObjectMutators::DroMutator.call(cocina_object:, cocina_model:)
        return model_mutated unless resource_types_should_change?

        model_mutated.new(structural: model_mutated.structural.new(
          contains: Array(cocina_object.structural&.contains).map do |resource|
            next resource unless resource.type == current_resource_type

            resource.new(type: new_resource_type)
          end
        ))
      end

      def resource_types_should_change?
        Array(cocina_object.structural&.contains).map(&:type).any?(current_resource_type)
      end

      def update_viewing_direction?
        viewing_direction.present? && cocina_model.content_type.in?(Constants::CONTENT_TYPES_WITH_VIEWING_DIRECTIONS)
      end

      def update_cocina_model
        if new_content_type.present?
          cocina_model.content_type = new_content_type
          if Constants::CONTENT_TYPES_WITH_VIEWING_DIRECTIONS.exclude?(new_content_type)
            cocina_model.viewing_direction = nil
          end
        end
        cocina_model.viewing_direction = viewing_direction if update_viewing_direction?
      end
    end
  end
end
