# frozen_string_literal: true

# Form object for creating/updating an APO (Admin Policy Object)
# Note that this is a subclass of CocinaModels::AdminPolicy, not ApplicationForm.
class ApoForm < CocinaModels::AdminPolicy
  include PermittedParamsConcern
  include TitleFormConcern

  # All APOs registered here are governed by the uber APO.
  attribute :apo_druid, :string, default: -> { Settings.uber_apo_druid }

  def self.immutable_attributes
    [:apo_druid]
  end

  validates :title, presence: true
  before_validation :populate_description_hash_from_title, if: -> { title.present? }
end
