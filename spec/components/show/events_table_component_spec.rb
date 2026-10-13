# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::EventsTableComponent, type: :component do
  let(:component) { described_class.new(events:) }
  let(:events) do
    [
      Dor::Services::Client::Events::Event.new(event_type: 'version_open',
                                               data: { 'version' => '2', 'description' => 'Fix title',
                                                       'who' => 'jdoe' },
                                               timestamp: '2026-04-16T10:00:00Z'),
      Dor::Services::Client::Events::Event.new(event_type: 'registration',
                                               data: { 'request' => { 'type' => 'dro' } },
                                               timestamp: '2026-04-15T10:00:00Z'),
      Dor::Services::Client::Events::Event.new(event_type: 'user_version_created',
                                               data: { 'version' => '3', 'who' => 'asmith' },
                                               timestamp: '2026-04-14T10:00:00Z'),
      Dor::Services::Client::Events::Event.new(event_type: 'publishing_complete', data: {},
                                               timestamp: '2026-04-13T10:00:00Z')
    ]
  end

  before do
    render_inline(component)
  end

  it 'renders the headers' do
    expect(page).to have_table(id: 'events-table')
    expect(page).to have_css('th', text: 'When')
    expect(page).to have_css('th', text: 'Event type')
    expect(page).to have_css('th', text: 'Who')
    expect(page).to have_css('th', text: 'Version')
    expect(page).to have_css('th .visually-hidden', text: 'Show data')
  end

  it 'renders the rows for each event' do
    expect(page).to have_css('tbody tr', count: 6)
    expect(page).to have_css('tr.toggle-row-data', count: 2)
    expect(page).to have_css('tbody th', text: '2026-04-14 03:00:00 PT')
    expect(page).to have_css('tbody th', text: '2026-04-13 03:00:00 PT')
  end
end
