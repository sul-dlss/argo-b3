# frozen_string_literal: true

module CocinaModels
  # Concern for handling content type and viewing direction in Cocina models.
  module ContentTypeConcern
    extend ActiveSupport::Concern

    included do
      attribute :content_type, :string
      attribute :viewing_direction, :string
      validates :content_type, presence: true
      validates :content_type, inclusion: { in: Cocina::Models::DRO::TYPES }
      validates :viewing_direction, inclusion: { in: Constants::VIEWING_DIRECTIONS }, allow_nil: true
      validate :viewing_direction_only_for_applicable_content_types
    end

    private

    def viewing_direction_only_for_applicable_content_types
      return if viewing_direction.blank?
      return if Constants::CONTENT_TYPES_WITH_VIEWING_DIRECTIONS.include?(content_type)

      errors.add(:viewing_direction, 'is only valid for book and image content types')
    end
  end
end
