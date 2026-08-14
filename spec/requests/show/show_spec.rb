# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object' do
  let(:druid) { 'druid:bc123df4567' }

  before do
    sign_in(create(:user))
  end

  describe 'GET /objects/:druid' do
    context 'when the object is not found' do
      before do
        allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_raise(Sdr::Repository::NotFoundResponse)
      end

      it 'renders a 404' do
        get "/objects/#{druid}"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
