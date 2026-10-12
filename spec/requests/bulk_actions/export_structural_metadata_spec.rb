# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Export structural metadata bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_export_structural_metadata_path,
                  create_path: :bulk_actions_export_structural_metadata_path,
                  label: 'Export structural metadata',
                  action_type: 'EXPORT_STRUCTURAL_METADATA',
                  job_class: BulkActions::ExportStructuralMetadataJob
end
