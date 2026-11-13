# frozen_string_literal: true

# Configurations for bulk actions.
# A config with a form gets new and create routes, handled by BulkActions::FormsController unless it names a controller.
module BulkActions # rubocop:disable Metrics/ModuleLength
  # Sections of the new bulk actions page, in display order; each lists its configs in definition order.
  SECTIONS = {
    perform_actions: 'Perform actions',
    register_and_deposit: 'Register and deposit',
    tags_and_reporting: 'Tags and reporting',
    modify_objects: 'Modify objects',
    structural_metadata: 'Manage structural metadata',
    rights_and_administrative_metadata: 'Manage rights and administrative metadata',
    descriptive_metadata: 'Manage descriptive metadata',
    permissions: 'Manage permissions'
  }.freeze

  def self.find_config(bulk_action_type)
    constant_name = bulk_action_type.to_s.upcase
    return const_get(constant_name, false) if const_defined?(constant_name, false)

    # Bulk actions of a removed or renamed type remain in the history.
    Config.new(label: constant_name.humanize)
  end

  # @return [Array<Config>] the configs for all bulk action types defined in this module, in definition order
  def self.all
    @all ||= []
  end

  # @return [Array<Config>] the configs listed in the section
  def self.in_section(section)
    all.select { |config| config.section == section }
  end

  def self.register(**)
    Config.new(**).tap { |config| all << config }
  end
  private_class_method :register

  Config = Struct.new('BulkActionConfig',
                      :job,
                      # Form class; a config without one has no routes (e.g., REGISTER_FORM).
                      :form,
                      :label,
                      :help_text,
                      # Key of SECTIONS listing this bulk action on the new bulk actions page.
                      :section,
                      # Whether the form offers depositing (closing the version) once the action is complete.
                      :close_version,
                      # AdminPolicy rule a non-admin must pass to see and submit the bulk action.
                      :admin_policy_rule,
                      # Controller (within BulkActions) for the new and create routes.
                      :controller,
                      # Array of Export for the files created by this bulk action, if any.
                      :exports,
                      :cancellable) do
                        def initialize(cancellable: true, close_version: false, controller: 'forms', **)
                          super
                        end

                        # Convert BulkActions::AddWorkflowJob to 'ADD_WORKFLOW'
                        def action_type
                          job.to_s.demodulize.delete_suffix('Job').underscore.upcase
                        end

                        # The route name, e.g., 'add_workflow'.
                        def key
                          action_type.downcase
                        end

                        def routable?
                          form.present?
                        end

                        def exports
                          self[:exports] || []
                        end

                        def new_path
                          Rails.application.routes.url_helpers.public_send(:"new_bulk_actions_#{key}_path")
                        end

                        def create_path
                          Rails.application.routes.url_helpers.public_send(:"bulk_actions_#{key}_path")
                        end

                        def cancellable?
                          cancellable
                        end

                        def close_version?
                          close_version
                        end

                        def find_export(key)
                          exports.find { |export| export.key == key } ||
                            raise(ArgumentError, "Unknown export #{key} for #{action_type}")
                        end
                      end

  # A file created by a bulk action.
  # When show is true and the file is a CSV, the CSV is displayed as a table on the bulk action show page.
  Export = Struct.new('BulkActionExport', :key, :filename, :label, :show)

  REGISTER_EXPORTS = [
    Export.new(key: :registration_report, filename: 'registration_report.csv', label: 'Registration report',
               show: true),
    Export.new(key: :tracking_sheets, filename: 'tracking_sheets.pdf', label: 'Tracking sheets')
  ].freeze

  MANAGE_RELEASE = register(
    label: 'Manage release',
    help_text: 'Choose whether objects are released to SearchWorks, EarthWorks, and/or search engines.',
    job: BulkActions::ManageReleaseJob,
    form: BulkActions::ManageReleaseForm,
    section: :perform_actions
  )

  REPUBLISH = register(
    label: 'Republish',
    help_text: 'Sync changes to PURL, SearchWorks, etc.',
    job: BulkActions::RepublishJob,
    form: BulkActions::BasicForm,
    section: :perform_actions
  )

  REINDEX = register(
    label: 'Reindex',
    help_text: 'Reindex objects in Solr.',
    job: BulkActions::ReindexJob,
    form: BulkActions::BasicForm,
    section: :perform_actions
  )

  REGISTER_CSV = register(
    label: 'Register items',
    help_text: 'Register items with item-specific settings by uploading a spreadsheet.',
    exports: REGISTER_EXPORTS,
    job: BulkActions::RegisterCsvJob,
    form: BulkActions::RegisterForm,
    section: :register_and_deposit
  )

  REDEPOSIT = register(
    label: 'Redeposit',
    help_text: 'Deposit drafts, or open and deposit a new version of objects that are not in draft state.',
    job: BulkActions::RedepositJob,
    form: BulkActions::RedepositForm,
    section: :register_and_deposit
  )

  ADD_WORKFLOW = register(
    label: 'Add workflow',
    help_text: 'Start a specialized workflow.',
    job: BulkActions::AddWorkflowJob,
    form: BulkActions::AddWorkflowForm,
    section: :modify_objects,
    close_version: true
  )

  TEXT_EXTRACTION = register(
    label: 'Text extraction',
    help_text: 'Start text extraction workflow for the selected items.',
    job: BulkActions::TextExtractionJob,
    form: BulkActions::TextExtractionForm,
    section: :modify_objects
  )

  PURGE = register(
    label: 'Purge',
    help_text: 'Delete registered, undeposited objects.',
    job: BulkActions::PurgeJob,
    form: BulkActions::BasicForm,
    section: :modify_objects
  )

  REFRESH_METADATA = register(
    label: 'Refresh metadata from FOLIO',
    help_text: "Overwrite SDR descriptive metadata with the latest metadata from objects' FOLIO records.",
    job: BulkActions::RefreshMetadataJob,
    form: BulkActions::BasicForm,
    section: :descriptive_metadata,
    close_version: true
  )

  EXPORT_DESCRIPTIVE_METADATA = register(
    label: 'Download descriptive metadata spreadsheet',
    help_text: 'Download a spreadsheet listing Cocina descriptive metadata.',
    exports: [
      Export.new(key: :descriptive_metadata, filename: 'descriptive.csv', label: 'Descriptive metadata spreadsheet')
    ],
    job: BulkActions::ExportDescriptiveMetadataJob,
    cancellable: false,
    form: BulkActions::BasicForm,
    section: :descriptive_metadata
  )

  VALIDATE_DESCRIPTIVE_METADATA = register(
    label: 'Validate descriptive metadata spreadsheet',
    help_text: 'Validate a Cocina descriptive metadata spreadsheet without applying changes.',
    job: BulkActions::ValidateDescriptiveMetadataJob,
    form: BulkActions::ImportDescriptiveMetadataForm,
    section: :descriptive_metadata
  )

  IMPORT_DESCRIPTIVE_METADATA = register(
    label: 'Upload descriptive metadata spreadsheet',
    help_text: "Update objects' Cocina descriptive metadata by uploading a spreadsheet.",
    job: BulkActions::ImportDescriptiveMetadataJob,
    form: BulkActions::ImportDescriptiveMetadataForm,
    section: :descriptive_metadata,
    close_version: true
  )

  EXPORT_CATALOG_DATA = register(
    label: 'Export FOLIO instance HRIDs, barcodes and serials metadata',
    help_text: 'Download a spreadsheet containing FOLIO instance HRIDs, barcodes, part labels and sort keys.',
    exports: [Export.new(key: :catalog_data, filename: 'catalog_data.csv', label: 'Catalog data')],
    job: BulkActions::ExportCatalogDataJob,
    form: BulkActions::BasicForm,
    section: :descriptive_metadata
  )

  IMPORT_CATALOG_DATA = register(
    label: 'Import FOLIO instance HRIDs, barcodes and serials metadata',
    help_text: 'Update FOLIO instance HRIDs, barcodes, part labels and sort keys by uploading a spreadsheet.',
    job: BulkActions::ImportCatalogDataJob,
    form: BulkActions::ImportCatalogDataForm,
    section: :descriptive_metadata,
    close_version: true
  )

  EXPORT_MODS = register(
    label: 'Download descriptive metadata as MODS XML',
    help_text: nil,
    exports: [Export.new(key: :mods, filename: 'mods_export.zip', label: 'MODS XML')],
    job: BulkActions::ExportModsJob,
    form: BulkActions::BasicForm,
    section: :descriptive_metadata
  )

  MANAGE_RIGHTS = register(
    label: 'Update rights',
    help_text: "Update objects' view and download rights settings.",
    job: BulkActions::ManageRightsJob,
    form: BulkActions::ManageRightsForm,
    section: :rights_and_administrative_metadata,
    close_version: true
  )

  MANAGE_LICENSE_AND_RIGHTS_STATEMENTS = register(
    label: 'Update license and rights statements',
    help_text: "Update items' license, copyright statement, and/or use and reproduction statement.",
    job: BulkActions::ManageLicenseAndRightsStatementsJob,
    form: BulkActions::ManageLicenseAndRightsStatementsForm,
    section: :rights_and_administrative_metadata,
    close_version: true
  )

  MANAGE_EMBARGO = register(
    label: 'Manage embargo',
    help_text: 'Update embargo settings by uploading a spreadsheet.',
    job: BulkActions::ManageEmbargoJob,
    form: BulkActions::ManageEmbargoForm,
    section: :rights_and_administrative_metadata,
    close_version: true
  )

  UPDATE_GOVERNING_APO = register(
    label: 'Update governing APO',
    help_text: 'Move objects to a different governing APO.',
    job: BulkActions::UpdateGoverningApoJob,
    form: BulkActions::UpdateGoverningApoForm,
    section: :rights_and_administrative_metadata,
    close_version: true,
    controller: 'update_governing_apo'
  )

  APPLY_APO_DEFAULTS = register(
    label: 'Apply APO defaults',
    help_text: "Overwrite access settings and rights statements with the defaults from the objects' APO(s).",
    job: BulkActions::ApplyApoDefaultsJob,
    form: BulkActions::BasicForm,
    section: :rights_and_administrative_metadata,
    close_version: true
  )

  MANAGE_SOURCE_ID = register(
    label: 'Update source ID',
    help_text: "Update objects' source IDs by uploading a spreadsheet.",
    job: BulkActions::ManageSourceIdJob,
    form: BulkActions::ManageSourceIdForm,
    section: :rights_and_administrative_metadata,
    close_version: true
  )

  MANAGE_CONTENT_TYPE = register(
    label: 'Update content type',
    help_text: "Change items' content type.",
    job: BulkActions::ManageContentTypeJob,
    form: BulkActions::ManageContentTypeForm,
    section: :structural_metadata,
    close_version: true
  )

  EXPORT_STRUCTURAL_METADATA = register(
    label: 'Export structural metadata',
    help_text: "Download a spreadsheet of objects' structural metadata.",
    exports: [
      Export.new(key: :structural_metadata, filename: 'structural_metadata.csv',
                 label: 'Structural metadata spreadsheet')
    ],
    job: BulkActions::ExportStructuralMetadataJob,
    form: BulkActions::BasicForm,
    section: :structural_metadata
  )

  IMPORT_STRUCTURAL_METADATA = register(
    label: 'Import structural metadata',
    help_text: 'Update structural metadata by uploading a spreadsheet.',
    job: BulkActions::ImportStructuralMetadataJob,
    form: BulkActions::ImportStructuralMetadataForm,
    section: :structural_metadata,
    close_version: true
  )

  MANAGE_COLLECTIONS = register(
    label: 'Update collections',
    help_text: 'Add items to a collection or remove items from a collection.',
    job: BulkActions::ManageCollectionsJob,
    form: BulkActions::ManageCollectionsForm,
    section: :structural_metadata,
    close_version: true
  )

  CREATE_VIRTUAL_OBJECT = register(
    label: 'Create virtual object',
    help_text: 'Group druids into one or more virtual objects.',
    job: BulkActions::CreateVirtualObjectJob,
    form: BulkActions::CreateVirtualObjectForm,
    section: :structural_metadata
  )

  IMPORT_READ_UNRESTRICTED_WORKGROUPS = register(
    label: 'Import read unrestricted workgroups',
    help_text: 'Grants or revokes read unrestricted permission for workgroups with a CSV.',
    job: BulkActions::ImportReadUnrestrictedWorkgroupsJob,
    form: BulkActions::ImportReadUnrestrictedWorkgroupsForm,
    section: :permissions,
    admin_policy_rule: :manage_permissions?
  )

  IMPORT_READ_RESTRICTED_AND_EDIT_PERMISSIONS = register(
    label: 'Import read restricted and edit permissions',
    help_text: 'Grants or revokes read restricted or edit permissions on collections and APOs for ' \
               'workgroups with a CSV.',
    job: BulkActions::ImportReadRestrictedAndEditPermissionsJob,
    form: BulkActions::ImportReadRestrictedAndEditPermissionsForm,
    section: :permissions,
    admin_policy_rule: :manage_permissions?
  )

  EXPORT_TAGS = register(
    label: 'Export tags',
    help_text: "Download a spreadsheet listing objects' tags, including project and ticket tags.",
    exports: [Export.new(key: :tags, filename: 'tags.csv', label: 'Tags')],
    job: BulkActions::ExportTagsJob,
    form: BulkActions::BasicForm,
    section: :tags_and_reporting
  )

  IMPORT_TAGS = register(
    label: 'Import tags',
    help_text: 'Update tags, including project and ticket tags, by uploading a spreadsheet.',
    job: BulkActions::ImportTagsJob,
    form: BulkActions::ImportTagsForm,
    section: :tags_and_reporting
  )

  EXPORT_TRACKING_SHEETS = register(
    label: 'Download tracking sheets',
    help_text: 'Download PDF tracking sheets to use in digitization workflows.',
    exports: [
      Export.new(key: :tracking_sheets, filename: 'tracking_sheets.pdf', label: 'Tracking sheets')
    ],
    job: BulkActions::ExportTrackingSheetsJob,
    cancellable: false,
    form: BulkActions::BasicForm,
    section: :tags_and_reporting
  )

  EXPORT_CHECKSUM_REPORT = register(
    label: 'Download checksum report',
    help_text: 'Download a spreadsheet listing checksums and file size for each file.',
    exports: [
      Export.new(key: :checksum_report, filename: 'checksum_report.csv', label: 'Checksum report')
    ],
    job: BulkActions::ExportChecksumReportJob,
    form: BulkActions::BasicForm,
    section: :tags_and_reporting
  )

  EXPORT_COCINA_JSON = register(
    label: 'Download full Cocina JSON',
    help_text: nil,
    exports: [Export.new(key: :cocina_json, filename: 'cocina.jsonl.gz', label: 'Cocina JSON')],
    job: BulkActions::ExportCocinaJsonJob,
    form: BulkActions::BasicForm,
    section: :tags_and_reporting
  )

  REGISTER_FORM = register(
    label: 'Register new druids (via a form)',
    help_text: 'Register druids.',
    exports: REGISTER_EXPORTS,
    job: BulkActions::RegisterFormJob
  )
end
