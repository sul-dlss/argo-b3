# frozen_string_literal: true

# Configurations for bulk actions.
module BulkActions # rubocop:disable Metrics/ModuleLength
  def self.find_config(bulk_action_type)
    "BulkActions::#{bulk_action_type.to_s.upcase}".constantize
  end

  def self.to_path_helper(path_name)
    ->(*args) { Rails.application.routes.url_helpers.public_send(path_name, *args) }
  end

  Config = Struct.new('BulkActionConfig',
                      :job,
                      :form,
                      :label,
                      :help_text,
                      :path_helper,
                      # Filename for the export created by this bulk action, if any.
                      :export_filename,
                      :export_label,
                      keyword_init: true) do
                        def action_type
                          BulkActions.constants.find do |const_name|
                            BulkActions.const_get(const_name) == self
                          end
                        end
                      end

  ADD_WORKFLOW = Config.new(
    label: 'Add workflow',
    help_text: 'Starts a workflow for individual objects',
    job: BulkActions::AddWorkflowJob,
    path_helper: to_path_helper(:new_bulk_actions_add_workflow_path),
    form: BulkActions::AddWorkflowForm
  )

  APPLY_APO_DEFAULTS = Config.new(
    label: 'Apply APO defaults',
    help_text: 'Overwrite object metadata with the defaults from the APO',
    job: BulkActions::ApplyApoDefaultsJob,
    path_helper: to_path_helper(:new_bulk_actions_apply_apo_defaults_path),
    form: BulkActions::BasicForm
  )

  CLOSE_VERSION = Config.new(
    label: 'Close version',
    help_text: 'Close a version of the items so the changes can be accessioned. The items will retain ' \
               'the version description as entered when the item was opened for versioning.',
    job: BulkActions::CloseVersionJob,
    path_helper: to_path_helper(:new_bulk_actions_close_version_path),
    form: BulkActions::BasicForm
  )

  CREATE_VIRTUAL_OBJECT = Config.new(
    label: 'Create virtual object',
    help_text: 'Create one or more virtual objects.'
  )

  EXPORT_CATALOG_DATA = Config.new(
    label: 'Export FOLIO Instance HRIDs, barcodes, and serials metadata',
    help_text: 'Download FOLIO Instance HRIDs and barcodes as CSV (comma-separated values) for selected druids.'
  )

  EXPORT_CHECKSUM_REPORT = Config.new(
    label: 'Download checksum report',
    help_text: 'Download checksums of files in objects (as csv).'
  )

  EXPORT_COCINA_JSON = Config.new(
    label: 'Download full Cocina JSON',
    help_text: 'Download full Cocina JSON for objects.',
    export_filename: 'cocina.jsonl.gz',
    export_label: 'Cocina JSON',
    job: BulkActions::ExportCocinaJsonJob,
    path_helper: to_path_helper(:new_bulk_actions_export_cocina_json_path),
    form: BulkActions::BasicForm
  )

  EXPORT_DESCRIPTIVE_METADATA = Config.new(
    label: 'Download descriptive metadata spreadsheet',
    help_text: 'Download descriptive metadata for objects.',
    export_filename: 'descriptive.csv',
    export_label: 'Descriptive metadata spreadsheet',
    job: BulkActions::ExportDescriptiveMetadataJob,
    path_helper: to_path_helper(:new_bulk_actions_export_descriptive_metadata_path),
    form: BulkActions::BasicForm
  )

  EXPORT_MODS = Config.new(
    label: 'Download descriptive metadata as MODS XML',
    help_text: 'Download descriptive metadata for objects.'
  )

  EXPORT_STRUCTURAL_METADATA = Config.new(
    label: 'Export structural metadata',
    help_text: 'Export structural metadata as CSV (comma-separated values) for selected druids.',
    export_filename: 'structural_metadata.csv',
    export_label: 'Structural metadata spreadsheet',
    job: BulkActions::ExportStructuralMetadataJob,
    path_helper: to_path_helper(:new_bulk_actions_export_structural_metadata_path),
    form: BulkActions::BasicForm
  )

  EXPORT_TRACKING_SHEETS = Config.new(
    label: 'Download tracking sheets',
    help_text: 'Download PDF tracking sheets of objects.'
  )

  EXPORT_TAGS = Config.new(
    label: 'Export tags',
    help_text: 'Download tags as CSV (comma-separated values) for selected druids.',
    export_filename: 'tags.csv',
    export_label: 'Tags',
    job: BulkActions::ExportTagsJob,
    path_helper: to_path_helper(:new_bulk_actions_export_tags_path),
    form: BulkActions::BasicForm
  )

  EXTRACT_TEXT = Config.new(
    label: 'Text extraction',
    help_text: 'Start text extraction workflow for the selected items.'
  )

  IMPORT_CATALOG_DATA = Config.new(
    label: 'Import FOLIO Instance HRIDs, barcodes, and serials metadata',
    help_text: 'Adds or updates Folio Instance HRIDs and/or barcodes associated with objects.'
  )

  IMPORT_DESCRIPTIVE_METADATA = Config.new(
    label: 'Upload descriptive metadata spreadsheet',
    help_text: 'Upload descriptive metadata for objects.',
    job: BulkActions::ImportDescriptiveMetadataJob,
    path_helper: to_path_helper(:new_bulk_actions_import_descriptive_metadata_path),
    form: BulkActions::ImportDescriptiveMetadataForm
  )

  IMPORT_STRUCTURAL_METADATA = Config.new(
    label: 'Import structural metadata',
    help_text: 'Upload structural metadata as CSV (comma-separated values).'
  )

  IMPORT_TAGS = Config.new(
    label: 'Import tags',
    help_text: 'Upload tags as CSV (comma-separated values).'
  )

  MANAGE_COLLECTIONS = Config.new(
    label: 'Update collections',
    help_text: 'Set collection(s).'
  )

  MANAGE_CONTENT_TYPE = Config.new(
    label: 'Update content type',
    help_text: 'Set content type.'
  )

  MANAGE_EMBARGO = Config.new(
    label: 'Manage embargo',
    help_text: 'Manage embargoes with a CSV.'
  )

  MANAGE_GOVERNING_APO = Config.new(
    label: 'Update governing APO',
    help_text: 'Moves the object to a new governing APO.'
  )

  MANAGE_LICENSE_AND_RIGHTS_STATEMENTS = Config.new(
    label: 'Update licenses and rights statements',
    help_text: 'Edit license, copyright statement, and/or use & reproduction statements'
  )

  MANAGE_RELEASE = Config.new(
    label: 'Manage release',
    help_text: 'Adds release tags to individual objects.',
    job: BulkActions::ManageReleaseJob,
    path_helper: to_path_helper(:new_bulk_actions_manage_release_path),
    form: BulkActions::ManageReleaseForm
  )

  MANAGE_RIGHTS = Config.new(
    label: 'Update rights',
    help_text: 'Edit rights.'
  )

  MANAGE_SOURCE_ID = Config.new(
    label: 'Update source id',
    help_text: 'Adds or updates source IDs associated with objects.'
  )

  OPEN_NEW_VERSION = Config.new(
    label: 'Open new version',
    help_text: 'Open items not yet open for versioning.',
    job: BulkActions::OpenVersionJob,
    path_helper: to_path_helper(:new_bulk_actions_open_version_path),
    form: BulkActions::OpenVersionForm
  )

  PURGE = Config.new(
    label: 'Purge',
    help_text: 'Deletes unpublished objects.',
    job: BulkActions::PurgeJob,
    path_helper: to_path_helper(:new_bulk_actions_purge_path),
    form: BulkActions::BasicForm
  )

  REFRESH_METADATA = Config.new(
    label: 'Refresh metadata from FOLIO record',
    help_text: 'Refresh metadata from the catalog.'
  )

  REGISTER = Config.new(
    label: 'Register new druids (via CSV)',
    help_text: 'Register druids.',
    export_filename: 'registration_report.csv',
    export_label: 'Registration report',
    job: BulkActions::RegisterJob,
    path_helper: to_path_helper(:new_bulk_actions_register_path),
    form: BulkActions::RegisterForm
  )

  REINDEX = Config.new(
    label: 'Reindex',
    help_text: 'Reindexes the DOR object in Solr.',
    job: BulkActions::ReindexJob,
    path_helper: to_path_helper(:new_bulk_actions_reindex_path),
    form: BulkActions::BasicForm
  )

  REPUBLISH = Config.new(
    label: 'Republish',
    help_text: 'Republish objects. You still need to use the normal versioning process to make sure ' \
               'your changes are preserved.',
    job: BulkActions::RepublishJob,
    path_helper: to_path_helper(:new_bulk_actions_republish_path),
    form: BulkActions::BasicForm
  )

  VALIDATE_DESCRIPTIVE_METADATA = Config.new(
    label: 'Validate descriptive metadata spreadsheet',
    help_text: 'Validate descriptive metadata for objects.'
  )
end
