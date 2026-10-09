# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Redeposit bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_redeposit_path,
                  create_path: :bulk_actions_redeposit_path,
                  label: 'Redeposit',
                  action_type: 'REDEPOSIT',
                  job_class: BulkActions::RedepositJob
end
