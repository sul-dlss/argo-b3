# frozen_string_literal: true

module BulkActions
  # Component for selecting the source of items for a bulk action or report.
  class SelectSourceComponent < ApplicationComponent
    # @param radio_action [String, nil] Stimulus action added to both radios after radio#toggle
    # @param druids_radio_data [Hash] extra data attributes for the druid list radio
    # @param druid_list_data [Hash] data attributes for the druid list textarea
    def initialize(form:, search_form: nil, total_results: nil, label: 'Select source of items for bulk action', # rubocop:disable Metrics/ParameterLists
                   radio_action: nil, druids_radio_data: {}, druid_list_data: {})
      @form = form
      @search_form = search_form
      @total_results = total_results
      @label = label
      @radio_action = radio_action
      @druids_radio_data = druids_radio_data
      @druid_list_data = druid_list_data
      super()
    end

    attr_reader :form, :search_form, :total_results, :label, :druids_radio_data, :druid_list_data

    def last_search?
      search_form.present?
    end

    def radio_data
      { radio_target: 'radio', action: ['radio#toggle', @radio_action].compact.join(' ') }
    end
  end
end
