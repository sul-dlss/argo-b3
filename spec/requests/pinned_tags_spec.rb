# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PinnedTags' do
  let(:user) { create(:user) }
  let(:tag) { 'Project : Foo' }

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

    it 'does not destroy a pinned tag belonging to another user' do
      sign_in(create(:user))

      expect do
        delete pinned_tag_path(tag)
      end.not_to change(PinnedTag, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
