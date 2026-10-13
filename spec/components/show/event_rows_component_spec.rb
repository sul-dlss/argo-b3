# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::EventRowsComponent, type: :component do
  let(:component) { described_class.new(event:) }
  # Rendered within a table, since table rows are dropped when rendered as a standalone fragment.
  let(:table) do
    Capybara.string("<table><tbody>#{component.render_in(vc_test_view_context)}</tbody></table>")
  end

  context 'with an event with data' do
    let(:event) do
      Dor::Services::Client::Events::Event.new(event_type: 'version_open',
                                               data: { 'version' => '2', 'description' => 'Fix title',
                                                       'who' => 'jdoe' },
                                               timestamp: '2026-04-16T10:00:00Z')
    end

    it 'renders a toggleable row and a row with the data' do
      row = table.find("tr##{component.row_id}[data-bs-target='##{component.data_id}']")
      expect(row['data-bs-toggle']).to eq('collapse')
      expect(row[:class]).to include('collapsed')
      expect(row).to have_css('td .toggle-row-indicator')
      expect(row).to have_css('th', text: '2026-04-16 03:00:00 PT')
      cells = row.all('td')
      expect(cells[0]).to have_text('Version open')
      expect(cells[1]).to have_text('jdoe')
      expect(cells[2]).to have_text('2')

      data_row = table.find("tr##{component.data_id}.collapse")
      expect(data_row).to have_css('dt', text: 'Description')
      expect(data_row).to have_css('dd', text: 'Fix title')
      expect(data_row).to have_no_css('dt', text: 'Who')
      expect(data_row).to have_no_css('dt', text: 'Version')
    end
  end

  context 'with an event' do
    let(:event) do
      Dor::Services::Client::Events::Event.new(event_type: 'druid_version_replicated', data: {},
                                               timestamp: '2026-04-16T10:00:00.123Z')
    end

    it 'identifies the rows by the event type and timestamp' do
      expect(component.row_id).to eq('event-druid_version_replicated-2026-04-16t10-00-00-123z')
      expect(component.data_id).to eq('event-druid_version_replicated-2026-04-16t10-00-00-123z-data')
    end
  end

  context 'with an event with hash data' do
    let(:event) do
      Dor::Services::Client::Events::Event.new(event_type: 'registration',
                                               data: { 'request' => { 'type' => 'dro' } },
                                               timestamp: '2026-04-15T10:00:00Z')
    end

    it 'renders the value with the JSON viewer' do
      data_row = table.find("tr##{component.data_id}")
      expect(data_row).to have_css('dt', text: 'Request')
      expect(data_row).to have_css('dd andypf-json-viewer')
    end
  end

  context 'with an event with only a who and version' do
    let(:event) do
      Dor::Services::Client::Events::Event.new(event_type: 'user_version_created',
                                               data: { 'version' => '3', 'who' => 'asmith' },
                                               timestamp: '2026-04-14T10:00:00Z')
    end

    it 'does not render a toggleable row' do
      row = table.find('tr', text: 'User version created')
      expect(row['data-bs-toggle']).to be_nil
      cells = row.all('td')
      expect(cells[1]).to have_text('asmith')
      expect(cells[2]).to have_text('3')
      expect(row).to have_no_css('.toggle-row-indicator')
      expect(table).to have_no_css("tr##{component.data_id}")
    end
  end

  context 'with an event without data' do
    let(:event) do
      Dor::Services::Client::Events::Event.new(event_type: 'publishing_complete', data: {},
                                               timestamp: '2026-04-13T10:00:00Z')
    end

    it 'does not render a toggleable row' do
      row = table.find('tr', text: 'Publishing complete')
      expect(row['data-bs-toggle']).to be_nil
      expect(row).to have_no_css('.toggle-row-indicator')
      expect(table).to have_no_css("tr##{component.data_id}")
    end
  end
end
