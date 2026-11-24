# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionFinishedNotifier do
  include ActiveJob::TestHelper

  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }
  let(:toast_html) { [] }

  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to) do |*_args, html:, **|
      toast_html << Capybara.string(html)
    end
  end

  after { bulk_action.remove_output_directory! }

  context 'without errors' do
    before do
      perform_enqueued_jobs do
        described_class.with(record: bulk_action, label: 'Reindex', failure_count: 0).deliver(user)
      end
    end

    it 'records a notification for the user' do
      notification = user.notifications.sole
      expect(notification.record).to eq(bulk_action)
      expect(notification.title).to eq('Bulk action finished')
    end

    it 'broadcasts a disappearing toast linking to the bulk action' do
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
        .with('notifications', user, target: 'toast-container', html: kind_of(String))
      toast = toast_html.sole
      expect(toast).to have_css('.toast.toast-disappear', text: 'Bulk action finished')
      expect(toast).to have_link('Reindex completed.', href: "/bulk_actions/#{bulk_action.id}")
    end
  end

  context 'with errors' do
    before do
      perform_enqueued_jobs do
        described_class.with(record: bulk_action, label: 'Reindex', failure_count: 2).deliver(user)
      end
    end

    it 'broadcasts a red toast that does not disappear, linking to the bulk action' do
      toast = toast_html.sole
      expect(toast).to have_css('.toast .bg-stanford-digital-red', text: 'Bulk action finished with errors')
      expect(toast).to have_no_css('.toast-disappear')
      expect(toast).to have_link('Reindex completed with 2 errors.', href: "/bulk_actions/#{bulk_action.id}")
    end
  end

  context 'with a single error' do
    it 'renders the text for one error' do
      perform_enqueued_jobs do
        described_class.with(record: bulk_action, label: 'Reindex', failure_count: 1).deliver(user)
      end

      expect(toast_html.sole).to have_link('Reindex completed with 1 error.')
    end
  end
end
