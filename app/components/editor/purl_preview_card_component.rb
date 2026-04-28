# frozen_string_literal: true

class Editor::PurlPreviewCardComponent < ApplicationComponent
  def initialize(purl_preview:)
    @purl_preview = purl_preview
    super()
  end

  attr_reader :purl_preview
end
