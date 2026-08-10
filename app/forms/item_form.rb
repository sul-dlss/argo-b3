# frozen_string_literal: true

# Form object for creating/updating an Item (DRO)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm.
class ItemForm < CocinaModels::Dro
  include PermittedParamsConcern

  attribute :title, :string
  normalizes :title, with: ->(title) { title.strip }
  validates :title, presence: true

  before_validation :populate_description_hash, if: -> { title.present? }

  private

  def populate_description_hash
    self.description_hash = { title: [{ value: title }] }
  end
end
