# frozen_string_literal: true

# Form object for registering a new Agreement (a DRO with the agreement content type)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm. See README for explanation.
class NewAgreementForm < CocinaModels::Dro
  # Keeps the "agreement" param key and field names (e.g., agreement[title]) rather than "new_agreement".
  model_name_for :agreement

  include PermittedParamsConcern
  include TitleFormConcern
  include TagsFormConcern

  # All agreements are dark and governed by the ur APO (Internal System Objects).
  attribute :content_type, :string, default: Cocina::Models::ObjectType.agreement
  attribute :apo_druid, :string, default: -> { Settings.ur_apo_druid }
  attribute :access_view, :string, default: 'dark'
  attribute :access_download, :string, default: 'none'

  def self.immutable_attributes
    %i[content_type apo_druid access_view access_download access_location]
  end

  validates :title, presence: true
  before_validation :populate_description_hash_from_title, if: -> { title.present? }
end
