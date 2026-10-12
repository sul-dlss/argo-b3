# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Export checksum report bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_export_checksum_report_path,
                  create_path: :bulk_actions_export_checksum_report_path,
                  label: 'Download checksum report',
                  action_type: 'EXPORT_CHECKSUM_REPORT',
                  job_class: BulkActions::ExportChecksumReportJob
end
