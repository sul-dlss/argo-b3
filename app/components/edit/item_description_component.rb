# frozen_string_literal: true

module Edit
  # Component for rendering the description tab of the item edit form.
  class ItemDescriptionComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder] for an EditItemForm
    # @param druid_token [String] the token for the item's druid
    def initialize(form:, druid_token:)
      @form = form
      @druid_token = druid_token
      super()
    end

    attr_reader :form, :druid_token
  end
end
