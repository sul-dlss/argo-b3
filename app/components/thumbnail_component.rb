# frozen_string_literal: true

# Component to render a thumbnail for a search result item
class ThumbnailComponent < ApplicationComponent
  include ActionView::Helpers::TextHelper

  def initialize(result:, dimension: 400, classes: [])
    @result = result
    @dimension = dimension
    @classes = classes
    super()
  end

  attr_reader :result, :dimension

  def render?
    result.first_shelved_image.present?
  end

  def call
    image_tag thumbnail_url, class: classes, alt: ''
  end

  private

  def classes
    merge_classes('thumbnail', @classes)
  end

  def thumbnail_file_id
    File.basename(result.first_shelved_image, '.*')
  end

  def thumbnail_url
    "#{Settings.stacks.url}/iiif/#{result.bare_druid}%2F#{ERB::Util.url_encode(thumbnail_file_id)}/full/!#{dimension},#{dimension}/0/default.jpg"
  end
end
