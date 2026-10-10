# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO defaults bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_apply_apo_defaults_path,
                  create_path: :bulk_actions_apply_apo_defaults_path,
                  label: 'Apply APO defaults',
                  action_type: 'APPLY_APO_DEFAULTS',
                  job_class: BulkActions::ApplyApoDefaultsJob,
                  with_close_version: true
end
