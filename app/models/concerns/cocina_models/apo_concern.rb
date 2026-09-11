# frozen_string_literal: true

module CocinaModels
  # Concern for handling the governing APO (admin policy) in Cocina models.
  module ApoConcern
    extend ActiveSupport::Concern

    included do
      # All objects have an admin policy (APO)
      attribute :apo_druid, :string
      validates :apo_druid, presence: true
    end
  end
end
