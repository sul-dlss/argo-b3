# frozen_string_literal: true

# Form for applying the governing APO's access and rights defaults to an Item, then depositing or saving as a draft.
# Note that this is a subclass of CocinaModels::Dro, not ApplicationForm.
class ItemApoDefaultsForm < CocinaModels::Dro
  model_name_for :apo_defaults

  include ContentDepositFormConcern
  include FileAccessFormConcern
  include ApplyApoDefaultsFormConcern

  # Unlike Edit item, the files keep their access unless the user chooses to overwrite it (or the item is made dark).
  attribute :overwrite_file_access, :boolean, default: false

  form_only_attributes :overwrite_file_access

  # Only the version description and the overwrite choice are submitted, so nothing else about the item can be
  # changed.
  def self.permitted_params
    %i[version_description overwrite_file_access]
  end

  # A background job may change the lock or structure of a busy Content, so saving is refused.
  def content_busy?
    content&.busy?
  end

  private

  # The access applies now and, for an embargoed item, once the embargo ends; the release date is kept.
  def apply_apo_defaults
    super
    access = { view: apo.access_view, download: apo.access_download, location: apo.access_location }
    update(access.transform_keys { |right| "access_#{right}" })
    update(access.transform_keys { |right| "embargo_#{right}" }) if embargo_release_date?
  end

  # As in Edit item, a change to the access is applied to the files of the cocina object and, unless depositing,
  # of the content.
  def around_content_save(accession:)
    overwrite = content_file_access_overwrite
    yield
    # The content has no unsaved changes, so it matches what is deposited.
    accession ? content&.destroy! : overwrite_content_file_access!(overwrite)
  ensure
    rebase_content_lock
  end
end
