# frozen_string_literal: true

# Configurations for bulk actions.
module BulkActions # rubocop:disable Metrics/ModuleLength
  def self.find_config(bulk_action_type)
    "#{name}::#{bulk_action_type.to_s.upcase}".constantize
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
                      # When true and export file is a CSV, displays the CSV as a table on bulk action show page.
                      :show_export,
                      :export_label) do
                        # Convert BulkActions::AddWorkflowJob to 'ADD_WORKFLOW'
                        def action_type
                          job.to_s.demodulize.delete_suffix('Job').underscore.upcase
                        end
                      end

  ADD_WORKFLOW = Config.new(
    label: 'Add workflow',
    help_text: 'Start a specialized workflow.',
    job: BulkActions::AddWorkflowJob,
    path_helper: to_path_helper(:new_bulk_actions_add_workflow_path),
    form: BulkActions::AddWorkflowForm
  )

  APPLY_APO_DEFAULTS = Config.new(
    label: 'Apply APO defaults',
    help_text: 'Overwrite access settings and rights statements with the defaults from the objects’ APO(s).',
    job: BulkActions::ApplyApoDefaultsJob,
    path_helper: to_path_helper(:new_bulk_actions_apply_apo_defaults_path),
    form: BulkActions::BasicForm
  )

  REDEPOSIT = Config.new(
    label: 'Redeposit',
    help_text: 'Deposit objects without making additional changes.',
    job: BulkActions::RedepositJob,
    path_helper: to_path_helper(:new_bulk_actions_redeposit_path),
    form: BulkActions::BasicForm
  )

  CREATE_VIRTUAL_OBJECT = Config.new(
    label: 'Create virtual object',
    help_text: 'Group druids into one or more virtual objects.'
  )

  EXPORT_CATALOG_DATA = Config.new(
    label: 'Export FOLIO instance HRIDs, barcodes and serials metadata',
    help_text: 'Download a spreadsheet containing FOLIO instance HRIDs, barcodes, part labels and sort keys.',
    export_filename: 'catalog_data.csv',
    export_label: 'Catalog data',
    job: BulkActions::ExportCatalogDataJob,
    path_helper: to_path_helper(:new_bulk_actions_export_catalog_data_path),
    form: BulkActions::BasicForm
  )

  EXPORT_CHECKSUM_REPORT = Config.new(
    label: 'Download checksum report',
    help_text: 'Download a spreadsheet listing checksums and file size for each file.',
    export_filename: 'checksum_report.csv',
    export_label: 'Checksum report',
    job: BulkActions::ExportChecksumReportJob,
    path_helper: to_path_helper(:new_bulk_actions_export_checksum_report_path),
    form: BulkActions::BasicForm
  )

  EXPORT_COCINA_JSON = Config.new(
    label: 'Download full Cocina JSON',
    help_text: nil,
    export_filename: 'cocina.jsonl.gz',
    export_label: 'Cocina JSON',
    job: BulkActions::ExportCocinaJsonJob,
    path_helper: to_path_helper(:new_bulk_actions_export_cocina_json_path),
    form: BulkActions::BasicForm
  )

  EXPORT_DESCRIPTIVE_METADATA = Config.new(
    label: 'Download descriptive metadata spreadsheet',
    help_text: 'Download a spreadsheet listing Cocina descriptive metadata.',
    export_filename: 'descriptive.csv',
    export_label: 'Descriptive metadata spreadsheet',
    job: BulkActions::ExportDescriptiveMetadataJob,
    path_helper: to_path_helper(:new_bulk_actions_export_descriptive_metadata_path),
    form: BulkActions::BasicForm
  )

  EXPORT_MODS = Config.new(
    label: 'Download descriptive metadata as MODS XML',
    help_text: nil,
    export_filename: 'mods_export.zip',
    export_label: 'MODS XML',
    job: BulkActions::ExportModsJob,
    path_helper: to_path_helper(:new_bulk_actions_export_mods_path),
    form: BulkActions::BasicForm
  )

  EXPORT_STRUCTURAL_METADATA = Config.new(
    label: 'Export structural metadata',
    help_text: 'Download a spreadsheet of objects’ structural metadata.',
    export_filename: 'structural_metadata.csv',
    export_label: 'Structural metadata spreadsheet',
    job: BulkActions::ExportStructuralMetadataJob,
    path_helper: to_path_helper(:new_bulk_actions_export_structural_metadata_path),
    form: BulkActions::BasicForm
  )

  EXPORT_TRACKING_SHEETS = Config.new(
    label: 'Download tracking sheets',
    help_text: 'Download PDF tracking sheets to use in digitization workflows.',
    export_filename: 'tracking_sheets.pdf',
    export_label: 'Tracking sheets',
    job: BulkActions::ExportTrackingSheetsJob,
    path_helper: to_path_helper(:new_bulk_actions_export_tracking_sheets_path),
    form: BulkActions::BasicForm
  )

  EXPORT_TAGS = Config.new(
    label: 'Export tags',
    help_text: 'Download a spreadsheet listing objects’ tags, including project and ticket tags.',
    export_filename: 'tags.csv',
    export_label: 'Tags',
    job: BulkActions::ExportTagsJob,
    path_helper: to_path_helper(:new_bulk_actions_export_tags_path),
    form: BulkActions::BasicForm
  )

  EXTRACT_TEXT = Config.new(
    label: 'Extract text',
    help_text: 'Perform OCR on book or image items.'
  )

  IMPORT_CATALOG_DATA = Config.new(
    label: 'Import FOLIO instance HRIDs, barcodes and serials metadata',
    help_text: 'Update FOLIO instance HRIDs, barcodes, part labels and sort keys by uploading a spreadsheet.',
    job: BulkActions::ImportCatalogDataJob,
    path_helper: to_path_helper(:new_bulk_actions_import_catalog_data_path),
    form: BulkActions::ImportCatalogDataForm
  )

  IMPORT_DESCRIPTIVE_METADATA = Config.new(
    label: 'Upload descriptive metadata spreadsheet',
    help_text: 'Update objects\' Cocina descriptive metadata by uploading a spreadsheet.',
    job: BulkActions::ImportDescriptiveMetadataJob,
    path_helper: to_path_helper(:new_bulk_actions_import_descriptive_metadata_path),
    form: BulkActions::ImportDescriptiveMetadataForm
  )

  IMPORT_READ_RESTRICTED_AND_EDIT_PERMISSIONS = Config.new(
    label: 'Import read restricted and edit permissions',
    help_text: 'Grants or revokes read restricted or edit permissions on collections and APOs for ' \
               'workgroups with a CSV.',
    job: BulkActions::ImportReadRestrictedAndEditPermissionsJob,
    path_helper: to_path_helper(:new_bulk_actions_import_read_restricted_and_edit_permissions_path),
    form: BulkActions::ImportReadRestrictedAndEditPermissionsForm
  )

  IMPORT_READ_UNRESTRICTED_WORKGROUPS = Config.new(
    label: 'Import read unrestricted workgroups',
    help_text: 'Grants or revokes read unrestricted permission for workgroups with a CSV.',
    job: BulkActions::ImportReadUnrestrictedWorkgroupsJob,
    path_helper: to_path_helper(:new_bulk_actions_import_read_unrestricted_workgroups_path),
    form: BulkActions::ImportReadUnrestrictedWorkgroupsForm
  )

  IMPORT_STRUCTURAL_METADATA = Config.new(
    label: 'Import structural metadata',
    help_text: 'Update structural metadata by uploading a spreadsheet.'
  )

  IMPORT_TAGS = Config.new(
    label: 'Import tags',
    help_text: 'Update tags, including project and ticket tags, by uploading a spreadsheet.'
  )

  MANAGE_COLLECTIONS = Config.new(
    label: 'Update collections',
    help_text: 'Add items to a collection or remove items from a collection.'
  )

  MANAGE_CONTENT_TYPE = Config.new(
    label: 'Update content type',
    help_text: 'Change items’ content type.',
    job: BulkActions::ManageContentTypeJob,
    path_helper: to_path_helper(:new_bulk_actions_manage_content_type_path),
    form: BulkActions::ManageContentTypeForm
  )

  MANAGE_EMBARGO = Config.new(
    label: 'Manage embargo',
    help_text: 'Update embargo settings by uploading a spreadsheet.',
    job: BulkActions::ManageEmbargoJob,
    path_helper: to_path_helper(:new_bulk_actions_manage_embargo_path),
    form: BulkActions::ManageEmbargoForm
  )

  MANAGE_LICENSE_AND_RIGHTS_STATEMENTS = Config.new(
    label: 'Update license and rights statements',
    help_text: 'Update items’ license, copyright statement, and/or use and reproduction statement.',
    job: BulkActions::ManageLicenseAndRightsStatementsJob,
    path_helper: to_path_helper(:new_bulk_actions_manage_license_and_rights_statements_path),
    form: BulkActions::ManageLicenseAndRightsStatementsForm
  )

  MANAGE_RELEASE = Config.new(
    label: 'Manage release',
    help_text: 'Choose whether objects are released to SearchWorks, EarthWorks, and/or search engines.',
    job: BulkActions::ManageReleaseJob,
    path_helper: to_path_helper(:new_bulk_actions_manage_release_path),
    form: BulkActions::ManageReleaseForm
  )

  MANAGE_RIGHTS = Config.new(
    label: 'Update rights',
    help_text: 'Update objects’ view and download rights settings.',
    job: BulkActions::ManageRightsJob,
    path_helper: to_path_helper(:new_bulk_actions_manage_rights_path),
    form: BulkActions::ManageRightsForm
  )

  MANAGE_SOURCE_ID = Config.new(
    label: 'Update source ID',
    help_text: 'Update objects’ source IDs by uploading a spreadsheet.',
    job: BulkActions::ManageSourceIdJob,
    path_helper: to_path_helper(:new_bulk_actions_manage_source_id_path),
    form: BulkActions::ManageSourceIdForm
  )

  PURGE = Config.new(
    label: 'Purge',
    help_text: 'Delete registered, undeposited objects.',
    job: BulkActions::PurgeJob,
    path_helper: to_path_helper(:new_bulk_actions_purge_path),
    form: BulkActions::BasicForm
  )

  REFRESH_METADATA = Config.new(
    label: 'Refresh metadata from FOLIO',
    help_text: 'Overwrite SDR descriptive metadata with the latest metadata from objects’ FOLIO records.',
    job: BulkActions::RefreshMetadataJob,
    path_helper: to_path_helper(:new_bulk_actions_refresh_metadata_path),
    form: BulkActions::BasicForm
  )

  REGISTER_CSV = Config.new(
    label: 'Register items',
    help_text: 'Register items with item-specific settings by uploading a spreadsheet.',
    export_filename: 'registration_report.csv',
    export_label: 'Registration report',
    show_export: true,
    job: BulkActions::RegisterCsvJob,
    path_helper: to_path_helper(:new_bulk_actions_register_csv_path),
    form: BulkActions::RegisterForm
  )

  REGISTER_FORM = Config.new(
    label: 'Register new druids (via a form)',
    help_text: 'Register druids.',
    export_filename: 'registration_report.csv',
    export_label: 'Registration report',
    show_export: true,
    job: BulkActions::RegisterFormJob
  )

  REINDEX = Config.new(
    label: 'Reindex',
    help_text: 'Reindex objects in Solr.',
    job: BulkActions::ReindexJob,
    path_helper: to_path_helper(:new_bulk_actions_reindex_path),
    form: BulkActions::BasicForm
  )

  REPUBLISH = Config.new(
    label: 'Republish',
    help_text: 'Sync changes to PURL, SearchWorks, etc.',
    job: BulkActions::RepublishJob,
    path_helper: to_path_helper(:new_bulk_actions_republish_path),
    form: BulkActions::BasicForm
  )

  UPDATE_GOVERNING_APO = Config.new(
    label: 'Update governing APO',
    help_text: 'Move objects to a different governing APO.',
    job: BulkActions::UpdateGoverningApoJob,
    path_helper: to_path_helper(:new_bulk_actions_update_governing_apo_path),
    form: BulkActions::UpdateGoverningApoForm
  )

  VALIDATE_DESCRIPTIVE_METADATA = Config.new(
    label: 'Validate descriptive metadata spreadsheet',
    help_text: 'Validate a Cocina descriptive metadata spreadsheet without applying changes.'
  )
end
