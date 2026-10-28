# frozen_string_literal: true

module Item
  # Component for rendering the purge button (for a purgeable item) or the discard draft button (for a discardable
  # draft) of the item edit and manage files forms.
  class DiscardOrPurgeButtonComponent < ApplicationComponent
    # @param druid [String] The druid of the item
    # @param action [Symbol, nil] :purge, :discard_draft, or nil to render nothing
    # @param data [Hash] Additional data attributes for the link
    def initialize(druid:, action:, data: {})
      @druid = druid
      @action = action
      @data = data
      super()
    end

    def render?
      action.present?
    end

    # @return [Hash] the link, label, and confirm text for the action
    def button
      {
        purge: { link: purge_object_path(druid), label: t('edit.items.edit.buttons.purge'),
                 confirm: t('edit.items.edit.buttons.purge_confirm') },
        discard_draft: { link: discard_draft_object_path(druid), label: t('edit.items.edit.buttons.discard_draft'),
                         confirm: t('edit.items.edit.buttons.discard_draft_confirm') }
      }.fetch(action)
    end

    private

    attr_reader :druid, :action, :data
  end
end
