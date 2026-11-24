# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::RecentTableComponent, type: :component do
  let(:user) { create(:user) }

  context 'with notifications' do
    let(:bulk_action) { create(:bulk_action, user:, description: 'Reindex maps') }
    let(:failed_bulk_action) { create(:bulk_action, user:, druid_count_total: 1200) }
    # Notifications are passed newest first. Noticed timestamps them in the database, so they are set here.
    let(:notifications) do
      [BulkActionFinishedNotifier.with(record: failed_bulk_action, label: 'Reindex', failure_count: 1100)
                                 .deliver(user).notifications.sole.tap { it.update!(created_at: 4.minutes.ago) },
       BulkActionFinishedNotifier.with(record: bulk_action, label: 'Reindex', failure_count: 0)
                                 .deliver(user).notifications.sole.tap { it.update!(created_at: 2.hours.ago) }]
    end

    after do
      bulk_action.remove_output_directory!
      failed_bulk_action.remove_output_directory!
    end

    it 'renders a row per notification with its subject, title, detail, and when it was sent' do
      render_inline(described_class.new(notifications:))

      table = page.find('table#notifications-table')
      expect(table['aria-label']).to eq('Recent notifications')
      expect(table.all('th').map { it.text.strip }).to eq(%w[About Notification When])

      rows = table.all('tbody tr')
      expect(rows.size).to eq(2)

      expect(rows[0]).to have_link('Reindex', exact_text: true, href: "/bulk_actions/#{failed_bulk_action.id}")
      expect(rows[0]).to have_css('td', text: 'Bulk action finished with errors')
      expect(rows[0]).to have_css('td div', exact_text: '1,100 of 1,200 objects failed.')
      expect(rows[0]).to have_css('time[title$=" PT"]', exact_text: '4 minutes ago')

      expect(rows[1]).to have_link('Reindex (Reindex maps)', href: "/bulk_actions/#{bulk_action.id}")
      expect(rows[1]).to have_css('td', exact_text: 'Bulk action finished', normalize_ws: true)
      expect(rows[1]).to have_css('time', exact_text: 'about 2 hours ago')
    end
  end

  context 'without notifications' do
    it 'renders the empty message' do
      render_inline(described_class.new(notifications: []))

      expect(page).to have_text('No notifications.')
    end
  end
end
