# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PinnedObjects' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:turbo_stream_headers) { { 'Accept' => 'text/vnd.turbo-stream.html, text/html' } }

  before do
    sign_in(user)
  end

  describe 'POST /pinned_objects' do
    it 'creates a pinned object for the current user and shows a toast' do
      expect do
        post pinned_objects_path, params: { druid: }
      end.to change(PinnedObject, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:toast]).to eq('Pin added')
      expect(PinnedObject.last.user).to eq(user)
      expect(PinnedObject.last.druid).to eq(druid)
    end

    context 'when a Turbo request' do
      it 'shows the toast and refreshes the page with a turbo stream' do
        post pinned_objects_path, params: { druid: }, headers: turbo_stream_headers

        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response.body).to include('turbo-stream action="append" target="toast-container"')
        expect(response.body).to include('Pin added')
        expect(response.body).to include('turbo-stream action="refresh"')
        expect(response.body).not_to include('request-id')
        expect(flash[:toast]).to be_nil
      end
    end
  end

  describe 'DELETE /pinned_objects/:id' do
    before { PinnedObject.create!(user:, druid:) }

    it 'destroys the pinned object and shows a toast' do
      expect do
        delete pinned_object_path(druid)
      end.to change(PinnedObject, :count).by(-1)

      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:toast]).to eq('Pin removed')
    end

    context 'when a Turbo request' do
      it 'shows the toast and refreshes the page with a turbo stream' do
        delete pinned_object_path(druid), headers: turbo_stream_headers

        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response.body).to include('turbo-stream action="append" target="toast-container"')
        expect(response.body).to include('Pin removed')
        expect(response.body).to include('turbo-stream action="refresh"')
        expect(response.body).not_to include('request-id')
        expect(flash[:toast]).to be_nil
      end
    end
  end
end
