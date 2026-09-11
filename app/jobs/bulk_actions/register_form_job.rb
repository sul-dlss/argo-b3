# frozen_string_literal: true

module BulkActions
  # Job to register objects from a form submission. This job is used for multiple item registration.
  class RegisterFormJob < BaseRegisterJob
    def perform(bulk_action:, items_registration_form:)
      @items_registration_form = items_registration_form
      super
    end

    def registrations
      items_registration_form.item_registrations
    end

    attr_reader :items_registration_form

    # Register a single object
    class JobItem < BaseRegisterJobItem
      alias item_registration_form registration

      delegate :items_registration_form, to: :job

      def register
        build_dro.tap { |dro| dro.create!(user_name: user_id) }.previous_cocina_object
      end

      def build_dro # rubocop:disable Metrics/AbcSize
        CocinaModels::Dro.new(
          source_id: item_registration_form.source_id,
          barcode: item_registration_form.barcode
        ).tap do |dro|
          if item_registration_form.title.present?
            dro.description_hash = { title: [{ value: item_registration_form.title }] }
          end
          if item_registration_form.catalog_record_id.present?
            dro.folio_catalog_links.new(catalog_record_id: item_registration_form.catalog_record_id)
            dro.catalog_link_refresh = true
          end
          dro.update(item_registration_form_attributes)
        end
      end

      def item_registration_form_attributes
        items_registration_form.attributes.symbolize_keys.slice(
          :content_type,
          :apo_druid,
          :use_and_reproduction_statement,
          :license,
          :copyright,
          :access_view,
          :access_download,
          :access_location,
          :embargo_release_date,
          :embargo_view,
          :embargo_download,
          :embargo_location
        )
      end
    end
  end
end
