# frozen_string_literal: true

# Model for a pinned search
class PinnedSearch < ApplicationRecord
  belongs_to :user

  before_save { self.search_form_md5 = self.class.md5_for(search_form_attributes) }

  validates :search_form_attributes, presence: true

  def to_search_form
    SearchForm.new(**search_form_attributes)
  end

  def self.create_from_search_form(search_form:, user:)
    create(search_form_attributes: search_form.attributes, user:)
  end

  def self.exists?(search_form:, user:)
    unscoped.exists?(user:, search_form_md5: md5_for(search_form.attributes))
  end

  def self.md5_for(search_form_attributes)
    Digest::MD5.hexdigest(search_form_attributes.to_json)
  end
end
