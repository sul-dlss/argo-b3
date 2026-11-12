# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show virtual object CSV' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:cocina_object) do
    build(:dro_with_metadata, id: druid)
      .new(structural: { hasMemberOrders: [{ members: ['druid:cd234fg5678', 'druid:df345gh6789'] }] })
  end

  before do
    sign_in(create(:user, :reader))
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
  end

  describe 'GET /objects/:druid/virtual_object_csv' do
    it 'sends the virtual object and its constituents as a CSV' do
      get "/objects/#{token}/virtual_object_csv"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('filename="bc123df4567_virtual_object.csv"')
      expect(response.body).to eq("bc123df4567,cd234fg5678,df345gh6789\n")
    end

    context 'when the object is not a virtual object' do
      let(:cocina_object) { build(:dro_with_metadata, id: druid) }

      it 'returns not found' do
        get "/objects/#{token}/virtual_object_csv"

        expect(response).to have_http_status(:not_found)
      end
    end

    it 'returns forbidden when token verification fails' do
      get '/objects/not-a-valid-token/virtual_object_csv'

      expect(response).to have_http_status(:forbidden)
    end
  end
end
