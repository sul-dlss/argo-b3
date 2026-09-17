# frozen_string_literal: true

# Model for a pinned search
class PinnedSearch < ApplicationRecord
  belongs_to :user

  before_save { self.search_form_md5 = self.class.md5_for(search_form_attributes) }

  validates :search_form_attributes, presence: true

  # Pinned searches are a saved query, so they always reopen as search results.
  def to_search_form
    ResultsSearchForm.new(**search_form_attributes)
  end

  def self.create_from_search_form(search_form:, user:)
    create(search_form_attributes: search_form.attributes, user:)
  end

  def self.exists_by_search_form?(search_form:, user:)
    exists?(user:, search_form_md5: md5_for(search_form.attributes))
  end

  # Note that the attributes are sorted before hashing. Attribute order is otherwise determined by
  # the order in which the form class declares its attributes, which would make the digest -- and
  # therefore whether an existing pin is recognized -- sensitive to a change in that order.
  def self.md5_for(search_form_attributes)
    Digest::MD5.hexdigest(search_form_attributes.sort.to_h.to_json)
  end
end
