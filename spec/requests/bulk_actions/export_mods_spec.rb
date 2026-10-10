# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Export MODS bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_export_mods_path,
                  create_path: :bulk_actions_export_mods_path,
                  label: 'Download descriptive metadata as MODS XML',
                  action_type: 'EXPORT_MODS',
                  job_class: BulkActions::ExportModsJob
end
