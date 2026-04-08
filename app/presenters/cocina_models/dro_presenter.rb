# frozen_string_literal: true

module CocinaModels
  # Presenter for Cocina DRO models.
  class DroPresenter < BasePresenter
    # @return [Array<String>] druids of the collections
    def collection_druids
      cocina_object.structural.isMemberOf
    end
  end
end
