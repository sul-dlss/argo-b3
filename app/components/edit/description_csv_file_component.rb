# frozen_string_literal: true

module Edit
  # Component for rendering the description spreadsheet upload field with a link to download the current description.
  # The form's object must include DescriptionCsvFormConcern.
  class DescriptionCsvFileComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder]
    # @param druid_token [String] the token for the druid whose description spreadsheet is downloaded
    # @param container_data [Hash] data attributes for the field's container
    def initialize(form:, druid_token:, container_data: {})
      @form = form
      @druid_token = druid_token
      @container_data = container_data
      super()
    end

    attr_reader :form, :druid_token, :container_data

    def download_link
      link_to(descriptive_csv_object_path(druid: druid_token), download: true, data: { turbo: false }) do
        safe_join([helpers.download_icon(aria: { hidden: true }, classes: 'me-1'),
                   t('edit.items.fields.description_csv_file.download')], ' ')
      end
    end
  end
end
