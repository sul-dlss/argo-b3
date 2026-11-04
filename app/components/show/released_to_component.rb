# frozen_string_literal: true

module Show
  # Component for rendering the released to box on the show page.
  class ReleasedToComponent < ApplicationComponent
    def initialize(object_released_presenter:)
      @object_released_presenter = object_released_presenter
      super()
    end

    attr_reader :object_released_presenter

    delegate :heading, :release_tag_links, :solr_doc, to: :object_released_presenter

    def release?
      object_released_presenter.manageable? && helpers.allowed_to?(:release?, solr_doc, with: ObjectPolicy)
    end
  end
end
