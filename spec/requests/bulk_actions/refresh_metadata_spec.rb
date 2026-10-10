# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Refresh metadata bulk action' do
  it_behaves_like 'a simple bulk action controller',
                  new_path: :new_bulk_actions_refresh_metadata_path,
                  create_path: :bulk_actions_refresh_metadata_path,
                  label: 'Refresh metadata from FOLIO',
                  action_type: 'REFRESH_METADATA',
                  job_class: BulkActions::RefreshMetadataJob,
                  with_close_version: true
end
