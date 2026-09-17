# frozen_string_literal: true

# Recomputes pinned search digests after two changes to how they are derived.
#
# search_form_md5 is a digest of search_form_attributes, and both changed:
#   1. page and sort moved from SearchForm to ResultsSearchForm, and the default page is no longer
#      serialized at all, so the stored attributes of an existing pin no longer match what the form
#      produces for the same search.
#   2. PinnedSearch.md5_for now sorts the attributes before hashing, so that the digest no longer
#      depends on the order in which the form class declares its attributes.
#
# Without this, an existing pin would not be recognized as pinned: the search would render as
# unpinned and pinning it again would insert a second row.
#
# Rehydrating each row through ResultsSearchForm rewrites the attributes as the current form
# produces them, and the model's before_save recomputes the digest.
class RenormalizePinnedSearchAttributes < ActiveRecord::Migration[8.1]
  def up
    PinnedSearch.find_each do |pinned_search|
      renormalize(pinned_search)
    end
  end

  def down
    # Everything this migration writes is derived from the search itself and is recomputed by the
    # model on save, so there is nothing to undo.
  end

  private

  def renormalize(pinned_search)
    attributes = ResultsSearchForm.new(**pinned_search.search_form_attributes).attributes

    # The collision is checked for rather than rescued: a unique violation would abort the
    # migration's transaction, leaving us unable to issue the delete.
    return destroy_duplicate(pinned_search) if duplicate?(pinned_search, attributes)

    # The digest is assigned explicitly rather than left to the model's before_save: if a row's
    # attributes are already canonical, nothing would be dirty and the save would be a no-op,
    # leaving a stale digest behind.
    pinned_search.update!(search_form_attributes: attributes,
                          search_form_md5: PinnedSearch.md5_for(attributes))
  end

  # Whether the user already has another pin that canonicalizes to the same digest. That happens
  # when the same search was pinned both before and after a change to the attributes, which produced
  # two rows that are now recognized as the same search.
  def duplicate?(pinned_search, attributes)
    PinnedSearch.where(user_id: pinned_search.user_id, search_form_md5: PinnedSearch.md5_for(attributes))
                .where.not(id: pinned_search.id)
                .exists?
  end

  def destroy_duplicate(pinned_search)
    say "Removing duplicate pinned search #{pinned_search.id} for user #{pinned_search.user_id}"
    pinned_search.destroy!
  end
end
