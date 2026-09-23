# frozen_string_literal: true

module Edit
  # Component for rendering edit form for the collections that an item is a member of.
  # Collections are selected by title or druid, with options loaded as the user types.
  class CollectionsComponent < ApplicationComponent
    # @param options [Array<Array(String, String)>] [label, druid] pairs for the selected collections
    def initialize(form:, options:)
      @form = form
      @options = options
      super()
    end

    attr_reader :form, :options

    def input_data
      {
        controller: 'tom-select',
        tom_select_url_value: collection_options_path,
        tom_select_placeholder_value: t('edit.items.fields.collection_druids.placeholder'),
        # When limiting by APO, the collections are limited to those governed by the selected APO.
        tom_select_form_params_value: {
          apo_druid: form.field_name(:apo_druid),
          limit_by_apo: form.field_name(:limit_collection_by_apo)
        }.to_json
      }
    end
  end
end
