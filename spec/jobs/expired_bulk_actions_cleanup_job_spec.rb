# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExpiredBulkActionsCleanupJob do
  let(:user) { create(:user) }

  let!(:expired_bulk_action) do
    create(:bulk_action, action_type: 'DOWNLOAD_FILES', user:, status: 'completed', created_at: 8.days.ago)
  end
  let!(:unexpired_bulk_action) do
    create(:bulk_action, action_type: 'DOWNLOAD_FILES', user:, status: 'completed', created_at: 6.days.ago)
  end
  let!(:running_bulk_action) do
    create(:bulk_action, action_type: 'DOWNLOAD_FILES', user:, status: 'started', created_at: 8.days.ago)
  end
  let!(:non_expiring_bulk_action) do
    create(:bulk_action, action_type: 'REINDEX', user:, status: 'completed', created_at: 30.days.ago)
  end

  after { BulkAction.find_each(&:remove_output_directory!) }

  it 'destroys the expired bulk actions and their files' do
    described_class.perform_now

    expect(BulkAction.all).to contain_exactly(unexpired_bulk_action, running_bulk_action, non_expiring_bulk_action)
    expect(File).not_to exist(expired_bulk_action.output_directory)
  end
end
