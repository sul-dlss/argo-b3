# frozen_string_literal: true

module Search
  # Component to render a thumbnail for a search result item
  class ThumbnailComponent < ApplicationComponent
    include ActionView::Helpers::TextHelper

    def initialize(result:)
      @result = result
      super()
    end

    attr_reader :result

    def show_thumbnail?
      thumbnail_url.present?
    end

    def placeholder_text
      truncate(citation, length: 246, omission: '…')
    end

    private

    def citation
      CitationPresenter.new(result:, italicize: false).call
    end

    def thumbnail_file_id
      File.basename(result.first_shelved_image, '.*') if result.first_shelved_image
    end

    def thumbnail_url
      return nil unless thumbnail_file_id

      "#{Settings.stacks.url}/iiif/#{result.bare_druid}%2F#{ERB::Util.url_encode(thumbnail_file_id)}/full/!400,400/0/default.jpg"
    end
  end
end
