# frozen_string_literal: true

# Form object for registering a new Agreement (a DRO with the agreement content type)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm. See README for explanation.
class NewAgreementForm < CocinaModels::Dro
  # Keeps the "agreement" param key and field names (e.g., agreement[title]) rather than "new_agreement".
  model_name_for :agreement

  include PermittedParamsConcern
  include TitleFormConcern
  include TagsFormConcern

  # Not permitted as params, since they are fixed (see below).
  def self.immutable_attributes
    %i[content_type apo_druid access_view access_download access_location]
  end

  # All agreements are dark and governed by the ur APO (Internal System Objects). These readers override the
  # inherited attribute readers so that the values cannot be changed by assigning them: an assigned value is
  # stored but never read.
  def content_type = Cocina::Models::ObjectType.agreement
  def apo_druid = Settings.ur_apo_druid
  def access_view = 'dark'
  def access_download = 'none'
  def access_location = nil

  validates :title, presence: true
  before_validation :populate_description_hash_from_title, if: -> { title.present? }
end
