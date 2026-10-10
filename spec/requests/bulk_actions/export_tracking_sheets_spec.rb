# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Export tracking sheets bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_export_tracking_sheets_path,
                  create_path: :bulk_actions_export_tracking_sheets_path,
                  label: 'Download tracking sheets',
                  action_type: 'EXPORT_TRACKING_SHEETS',
                  job_class: BulkActions::ExportTrackingSheetsJob
end
