# frozen_string_literal: true

module Edit
  # Component for rendering the description tab of the item and collection edit forms.
  # The form's object must include FolioCatalogLinksFormConcern, CocinaModels::CatalogLinksConcern, and
  # DescriptionCsvFormConcern, and, for the item fields, CocinaModels::BarcodeConcern.
  class DescriptionComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder] for an EditItemForm or EditCollectionForm
    # @param druid_token [String] the token for the object's druid
    # @param item_fields [Boolean] whether to render the fields only items have (barcode and serials)
    #   and the note about previewing a draft, since collections cannot be saved as a draft
    def initialize(form:, druid_token:, item_fields: true)
      @form = form
      @druid_token = druid_token
      @item_fields = item_fields
      super()
    end

    attr_reader :form, :druid_token

    def item_fields? = @item_fields
  end
end
