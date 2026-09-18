# frozen_string_literal: true

module CocinaModels
  # Presenter for a Collection cocina model.
  # It will delegate to the Collection model.
  # Initialize with: CollectionModels::CollectionPresenter.new(collection),
  # where collection is a CollectionModels::Collection.
  class CollectionPresenter < BasePresenter
    def display_access_rights
      "View: #{humanize_access_value(access_view)}"
    end
  end
end
