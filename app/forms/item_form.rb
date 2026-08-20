# frozen_string_literal: true

# Form object for creating/updating an Item (DRO)
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm.
class ItemForm < CocinaModels::Dro
  include PermittedParamsConcern

  SOURCE_ID_PROVIDED_CHOICE = 'provide'
  SOURCE_ID_GENERATE_CHOICE = 'generate'

  attribute :title, :string
  normalizes :title, with: ->(title) { title.strip }
  validates :title, presence: true

  attribute :source_id_choice, :string, default: SOURCE_ID_PROVIDED_CHOICE
  validates :source_id_choice, inclusion: { in: [SOURCE_ID_PROVIDED_CHOICE, SOURCE_ID_GENERATE_CHOICE] }

  attribute :source_id_prefix, :string
  normalizes :source_id_prefix, with: ->(source_id_prefix) { source_id_prefix.strip.delete_suffix(':') }
  validates :source_id_prefix, presence: true, if: -> { source_id_choice == SOURCE_ID_GENERATE_CHOICE }

  validate :source_id_must_be_unique, if: -> { source_id.present? }

  has_one :release_tags

  before_validation :populate_description_hash, if: -> { title.present? }
  before_validation :generate_source_id, if: lambda {
    source_id_choice == SOURCE_ID_GENERATE_CHOICE && source_id_prefix.present?
  }

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

  def generate_source_id
    self.source_id = "#{source_id_prefix}:#{SecureRandom.uuid}"
    self.source_id_choice = SOURCE_ID_PROVIDED_CHOICE
  end

  def source_id_must_be_unique
    return unless Sdr::Repository.source_id_exists?(source_id:)

    errors.add(:source_id, 'already exists')
  end
end
