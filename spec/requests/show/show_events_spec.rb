# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show events' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:invalid_token) { 'not-a-valid-token' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, events: events_client) }
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: events) }
  let(:event_types_client) do
    instance_double(Dor::Services::Client::EventTypes,
                    list: %w[argo_permission_created publishing_complete version_close version_open])
  end
  let(:events) do
    [Dor::Services::Client::Events::Event.new(event_type: 'version_open', data: {},
                                              timestamp: '2026-04-16T10:00:00Z')]
  end

  before do
    allow(Dor::Services::Client).to receive_messages(object: object_client, event_types: event_types_client)
    sign_in(create(:user))
  end

  describe 'GET /objects/:druid/events' do
    it 'raises when token verification fails' do
      get "/objects/#{invalid_token}/events"

      expect(response).to have_http_status(:forbidden)
      expect(Dor::Services::Client).not_to have_received(:object)
    end

    context 'when not filtered' do
      it 'lists the events for the default event types' do
        get "/objects/#{token}/events"

        expect(response).to have_http_status(:ok)
        expect(events_client).to have_received(:list)
          .with(event_types: %w[publishing_complete version_close version_open], from: nil, to: nil)
        expect(response.body).to include('Version open')
        page = Capybara.string(response.body)
        expect(page).to have_select('Event types',
                                    options: ['Argo permission created', 'Publishing complete', 'Version close',
                                              'Version open'],
                                    selected: ['Publishing complete', 'Version close', 'Version open'])
        expect(page).to have_button('Filter')
      end
    end

    context 'when filtered' do
      it 'lists the filtered events' do
        get "/objects/#{token}/events", params: {
          events_filter: { from: '2026-04-01T09:00', to: '2026-04-30T17:00', event_types: ['', 'version_open'] }
        }

        expect(events_client).to have_received(:list)
          .with(event_types: ['version_open'], from: Time.utc(2026, 4, 1, 16, 0), to: Time.utc(2026, 5, 1, 0, 0))
        page = Capybara.string(response.body)
        expect(page).to have_field('From', with: '2026-04-01T09:00')
        expect(page).to have_field('To', with: '2026-04-30T17:00')
        expect(page).to have_select('Event types', selected: ['Version open'])
      end
    end

    context 'when filtered with all event types selected' do
      it 'does not filter by event type' do
        get "/objects/#{token}/events", params: {
          events_filter: { from: '', to: '', event_types: ['', 'argo_permission_created', 'publishing_complete',
                                                           'version_close', 'version_open'] }
        }

        expect(events_client).to have_received(:list).with(event_types: nil, from: nil, to: nil)
      end
    end

    context 'when filtered with no event types selected' do
      it 'shows no events' do
        get "/objects/#{token}/events", params: { events_filter: { from: '', to: '', event_types: [''] } }

        expect(events_client).not_to have_received(:list)
        expect(response.body).to include('No events.')
      end
    end
  end
end
