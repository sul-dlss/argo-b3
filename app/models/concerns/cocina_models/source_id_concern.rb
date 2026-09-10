# frozen_string_literal: true

module CocinaModels
  # Concern for handling source id in Cocina models.
  module SourceIdConcern
    extend ActiveSupport::Concern

    included do
      attribute :source_id, :string
      normalizes_whitespace :source_id
      validates :source_id, presence: true
      validates :source_id, format: { with: /\A.+:.+\z/ }, allow_blank: true
    end
  end
end
