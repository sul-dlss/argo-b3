# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Export Cocina JSON bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_export_cocina_json_path,
                  create_path: :bulk_actions_export_cocina_json_path,
                  label: 'Download full Cocina JSON',
                  action_type: 'EXPORT_COCINA_JSON',
                  job_class: BulkActions::ExportCocinaJsonJob
end
