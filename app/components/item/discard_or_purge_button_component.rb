# frozen_string_literal: true

module Item
  # Component for rendering the purge button (for a purgeable item) or the discard draft button (for a discardable
  # draft) of the item edit and manage files forms.
  class DiscardOrPurgeButtonComponent < ApplicationComponent
    # @param draft_actions_presenter [DraftActionsPresenter] The button, rendered only if available
    # @param data [Hash] Additional data attributes for the link
    def initialize(draft_actions_presenter:, data: {})
      @draft_actions_presenter = draft_actions_presenter
      @data = data
      super()
    end

    def render?
      draft_actions_presenter.available?
    end

    private

    attr_reader :draft_actions_presenter, :data
  end
end
