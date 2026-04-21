# frozen_string_literal: true

module DescriptionEditor
  class PurlPreviewCardComponent < ApplicationComponent
    def initialize(purl_preview:, cocina_description_hash:)
      @purl_preview = purl_preview
      @cocina_description_hash = cocina_description_hash
      super()
    end

    attr_reader :purl_preview, :cocina_description_hash

    def title
      CocinaDisplay::CocinaRecord.new({ 'description' => cocina_description_hash }).display_title
    end
  end
end
