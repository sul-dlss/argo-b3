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

  it 'renders a toggleable row with the data for an event with data' do
    row = page.find('tr[data-bs-target="#event-0-data"]')
    expect(row['data-bs-toggle']).to eq('collapse')
    expect(row[:class]).to include('collapsed')
    expect(row).to have_css('td .event-toggle-indicator')
    expect(row).to have_css('th', text: '2026-04-16 03:00:00 PT')
    cells = row.all('td')
    expect(cells[0]).to have_text('Version open')
    expect(cells[1]).to have_text('jdoe')
    expect(cells[2]).to have_text('2')

    within('tr#event-0-data.collapse') do
      expect(page).to have_css('dt', text: 'Description')
      expect(page).to have_css('dd', text: 'Fix title')
      expect(page).to have_no_css('dt', text: 'Who')
      expect(page).to have_no_css('dt', text: 'Version')
    end
  end

  it 'renders hash and array values with the JSON viewer' do
    within('tr#event-1-data') do
      expect(page).to have_css('dt', text: 'Request')
      expect(page).to have_css('dd andypf-json-viewer')
    end
  end

  it 'does not render a toggleable row for an event with only a who and version' do
    row = page.find('tr', text: 'User version created')
    expect(row['data-bs-toggle']).to be_nil
    cells = row.all('td')
    expect(cells[1]).to have_text('asmith')
    expect(cells[2]).to have_text('3')
    expect(row).to have_no_css('.event-toggle-indicator')
    expect(page).to have_no_css('tr#event-2-data')
  end

  it 'does not render a toggleable row for an event without data' do
    row = page.find('tr', text: 'Publishing complete')
    expect(row['data-bs-toggle']).to be_nil
    expect(row).to have_no_css('.event-toggle-indicator')
    expect(page).to have_no_css('tr#event-3-data')
  end
end
