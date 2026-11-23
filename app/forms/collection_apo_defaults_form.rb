# frozen_string_literal: true

# Form for applying the governing APO's rights defaults to a Collection, then depositing it.
# As in Edit collection, view access is not changed, since an APO's default view may not apply to a collection.
# Note that this is a subclass of CocinaModels::Collection, not ApplicationForm.
class CollectionApoDefaultsForm < CocinaModels::Collection
  model_name_for :apo_defaults

  include EditCocinaObjectFormConcern
  include ApplyApoDefaultsFormConcern

  # Only the version description is submitted, so nothing else about the collection can be changed.
  def self.permitted_params
    %i[version_description]
  end

  # A collection has no files.
  def content_busy? = false

  # Always accessions, since a collection cannot be saved as a draft.
  # @param [String] user_name the sunetid of the user performing the action
  # @raise [ActiveModel::ValidationError] if the form is invalid
  def save!(user_name:, **)
    super(user_name:, accession: true)
  end
end
