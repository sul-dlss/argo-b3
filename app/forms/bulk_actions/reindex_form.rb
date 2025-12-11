# frozen_string_literal: true

module BulkActions
  # Form object for reindex bulk action.
  class ReindexForm < ApplicationForm
    attribute :source, :string, default: 'druids'
    attribute :druid_list, :string
    validates :druid_list, presence: true, if: -> { source == 'druids' }
    attribute :description, :string
  end
end
