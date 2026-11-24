# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationsCleanupJob do
  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }

  let!(:recent_event) { deliver(at: 29.days.ago) }

  before { deliver(at: 31.days.ago) }

  after { bulk_action.remove_output_directory! }

  def deliver(at:)
    travel_to(at) do
      BulkActionFinishedNotifier.with(record: bulk_action, label: 'Reindex', failure_count: 0)
                                .deliver(user, enqueue_job: false)
    end
  end

  it 'deletes notifications older than 30 days' do
    described_class.perform_now

    expect(Noticed::Event.all).to contain_exactly(recent_event)
    expect(user.notifications).to contain_exactly(recent_event.notifications.sole)
  end
end
