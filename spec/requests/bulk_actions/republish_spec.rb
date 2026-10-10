# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Republish bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_republish_path,
                  create_path: :bulk_actions_republish_path,
                  label: 'Republish',
                  action_type: 'REPUBLISH',
                  job_class: BulkActions::RepublishJob
end
