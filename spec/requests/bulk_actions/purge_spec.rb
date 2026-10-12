# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Purge bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_purge_path,
                  create_path: :bulk_actions_purge_path,
                  label: 'Purge',
                  action_type: 'PURGE',
                  job_class: BulkActions::PurgeJob
end
