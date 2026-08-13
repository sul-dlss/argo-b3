# frozen_string_literal: true

# Form object for creating/updating an Item (DRO)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm.
class ItemForm < CocinaModels::Dro
  include PermittedParamsConcern

  attribute :title, :string
  normalizes :title, with: ->(title) { title.strip }
  validates :title, presence: true

  has_one :release_tags

  before_validation :populate_description_hash, if: -> { title.present? }

  def initialize(attributes = {})
    super
    build_release_tags unless release_tags
  end

  def create!(user_name:)
    super

    release_tags.create!(druid:, user_name:)
  end

  private

  def populate_description_hash
    self.description_hash = { title: [{ value: title }] }
  end
end
