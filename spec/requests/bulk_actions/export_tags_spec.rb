# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Export tags bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_export_tags_path,
                  create_path: :bulk_actions_export_tags_path,
                  label: 'Export tags',
                  action_type: 'EXPORT_TAGS',
                  job_class: BulkActions::ExportTagsJob
end
