# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Export catalog data bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_export_catalog_data_path,
                  create_path: :bulk_actions_export_catalog_data_path,
                  label: 'Export FOLIO instance HRIDs, barcodes and serials metadata',
                  action_type: 'EXPORT_CATALOG_DATA',
                  job_class: BulkActions::ExportCatalogDataJob
end
