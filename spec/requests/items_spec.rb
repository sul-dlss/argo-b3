# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Items' do
  let(:user) { create(:user, :reader) }

  describe 'create' do
    context 'when invalid' do
      before do
        allow(Searchers::AdminPolicyList).to receive(:call).and_return([['My APO', 'druid:hv992ry2431']])
        allow(Searchers::CollectionListByDruid).to receive(:call)
          .and_return([['Art History Slides', 'druid:bc123df4567']])
        sign_in(user)
      end

      it 'renders the selected collections, labeling those not found with the bare druid' do
        # No title is provided, so the item is invalid.
        post '/items', params: { item: { collection_druids: ['', 'druid:bc123df4567', 'druid:xz987wv6543'] } }

        expect(response).to have_http_status(:unprocessable_content)
        page = Capybara.string(response.body)
        expect(page).to have_select('Collections', visible: :all, selected: ['Art History Slides', 'xz987wv6543'])
        expect(Searchers::CollectionListByDruid).to have_received(:call)
          .with(druids: %w[druid:bc123df4567 druid:xz987wv6543])
      end
    end
  end
end
