# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PinnedTags' do
  let(:user) { create(:user) }
  let(:tag) { 'Project : Foo' }

  let(:turbo_stream_headers) { { 'Accept' => 'text/vnd.turbo-stream.html, text/html' } }

  before do
    sign_in(user)
  end

  describe 'POST /pinned_tags' do
    it 'creates a pinned tag for the current user and shows a toast' do
      expect do
        post pinned_tags_path, params: { tag: }
      end.to change(PinnedTag, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:toast]).to eq('Pin added')
      expect(PinnedTag.last.user).to eq(user)
      expect(PinnedTag.last.tag).to eq(tag)
    end

    context 'when a Turbo request' do
      it 'shows the toast and refreshes the page with a turbo stream' do
        post pinned_tags_path, params: { tag: }, headers: turbo_stream_headers

        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response.body).to include('turbo-stream action="append" target="toast-container"')
        expect(response.body).to include('Pin added')
        expect(response.body).to include('turbo-stream action="refresh"')
        expect(response.body).not_to include('request-id')
        expect(flash[:toast]).to be_nil
      end
    end

    it 'is idempotent when the tag is already pinned' do
      PinnedTag.create!(user:, tag:)

      expect do
        post pinned_tags_path, params: { tag: }
      end.not_to change(PinnedTag, :count)
      expect(response).to have_http_status(:see_other)
    end
  end

  describe 'DELETE /pinned_tags/:id' do
    before { PinnedTag.create!(user:, tag:) }

    it 'destroys the pinned tag and shows a toast' do
      expect do
        delete pinned_tag_path(tag)
      end.to change(PinnedTag, :count).by(-1)

      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:toast]).to eq('Pin removed')
    end

    context 'when a Turbo request' do
      it 'shows the toast and refreshes the page with a turbo stream' do
        delete pinned_tag_path(tag), headers: turbo_stream_headers

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
