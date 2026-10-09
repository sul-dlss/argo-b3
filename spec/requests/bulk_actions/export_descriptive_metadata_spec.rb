# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Export descriptive metadata bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_export_descriptive_metadata_path,
                  create_path: :bulk_actions_export_descriptive_metadata_path,
                  label: 'Download descriptive metadata spreadsheet',
                  action_type: 'EXPORT_DESCRIPTIVE_METADATA',
                  job_class: BulkActions::ExportDescriptiveMetadataJob
end
