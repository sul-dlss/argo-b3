# frozen_string_literal: true

module CocinaModels
  # Concern for handling barcode in Cocina models.
  module BarcodeConcern
    extend ActiveSupport::Concern

    included do
      attribute :barcode, :string
      normalizes_whitespace :barcode
      validate :validate_barcode
    end

    private

    def validate_barcode
      return if barcode.nil?
      return if Cocina::Models::Barcode.valid?(barcode)

      errors.add(:barcode, 'is not a valid barcode')
    end
  end
end
