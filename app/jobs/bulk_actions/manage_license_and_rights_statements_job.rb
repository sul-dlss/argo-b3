# frozen_string_literal: true

module BulkActions
  # Job to update license and rights statements
  class ManageLicenseAndRightsStatementsJob < ClosingDruidsJob
    def perform(bulk_action:, druids:, close_version: false, # rubocop:disable Metrics/ParameterLists
                change_copyright: false, copyright: nil,
                change_license: false, license: nil,
                change_use_and_reproduction_statement: false, use_and_reproduction_statement: nil)
      @change_copyright = change_copyright
      @copyright = copyright
      @change_license = change_license
      @license = license
      @change_use_and_reproduction_statement = change_use_and_reproduction_statement
      @use_and_reproduction_statement = use_and_reproduction_statement
      super
    end

    attr_reader :change_copyright, :copyright, :change_license, :license, :change_use_and_reproduction_statement,
                :use_and_reproduction_statement

    # Update license and rights statements
    class JobItem < BaseJobItem
      delegate :change_copyright, :copyright, :change_license, :license,
               :change_use_and_reproduction_statement, :use_and_reproduction_statement, to: :job

      def perform # rubocop:disable Metrics/AbcSize
        return unless check_update_ability?

        unless cocina_object.dro? || cocina_object.collection?
          return failure!(message: "Not an item or collection (#{cocina_object.type})")
        end

        mutate_cocina_model

        return success!(message: 'No changes made') unless cocina_model.changed?

        open_new_version_if_needed!(description: description_msg)
        cocina_model.save!(user_name: user, description: description_msg)
        close_version_if_needed!

        success!(message: 'License/copyright/use statement(s) updated successfully')
      end

      private

      def description_msg
        'Updated license, copyright statement, and/or use and reproduction statement'
      end

      def mutate_cocina_model
        if change_use_and_reproduction_statement
          cocina_model.use_and_reproduction_statement = use_and_reproduction_statement
        end
        cocina_model.license = license if change_license
        cocina_model.copyright = copyright if change_copyright
      end
    end
  end
end
