# frozen_string_literal: true

module Search
  # Form for searching items (DROs, collections, or APOs)
  class ItemForm < Search::Form
    attribute :object_types, array: true, default: -> { [] }
    attribute :projects, array: true, default: -> { [] }
  end
end
