# frozen_string_literal: true

module Item
  # Component for rendering the purge button (for a purgeable item) or the discard draft button (for a discardable
  # draft) of the item edit and manage files forms.
  class DiscardOrPurgeButtonComponent < ApplicationComponent
    # @param discard_or_purge_presenter [DiscardOrPurgePresenter] The button, rendered only if available
    # @param data [Hash] Additional data attributes for the link
    def initialize(discard_or_purge_presenter:, data: {})
      @discard_or_purge_presenter = discard_or_purge_presenter
      @data = data
      super()
    end

    def render?
      discard_or_purge_presenter.available?
    end

    private

    attr_reader :discard_or_purge_presenter, :data
  end
end
