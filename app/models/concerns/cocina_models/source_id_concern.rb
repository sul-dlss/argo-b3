# frozen_string_literal: true

module CocinaModels
  # Concern for handling source id in Cocina models.
  module SourceIdConcern
    extend ActiveSupport::Concern

    SOURCE_ID_FORMAT = /\A.+:.+\z/

    included do
      attribute :source_id, :string
      normalizes_whitespace :source_id
      validates :source_id, presence: true
      validates :source_id, format: { with: SOURCE_ID_FORMAT }, allow_blank: true

      # Skipped for a persisted object whose source_id is unchanged, since the object would
      # find itself in the repository. Note that Voids clears dirty state in #initialize,
      # so a newly built (unpersisted) form always reports source_id_changed? == false.
      validate :source_id_must_be_unique,
               if: -> { source_id&.match?(SOURCE_ID_FORMAT) && (!persisted? || source_id_changed?) }
    end

    private

    def source_id_must_be_unique
      return unless Sdr::Repository.source_id_exists?(source_id:)

      errors.add(:source_id, I18n.t('edit.items.fields.source_id.validations.already_exists'))
    end
  end
end
