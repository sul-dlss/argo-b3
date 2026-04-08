# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View redirect' do
  describe 'GET /view/:druid' do
    let(:druid) { 'druid:bc123df4567' }

    it 'redirects to the object show page' do
      get "/view/#{druid}"

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/objects/#{druid}")
    end
  end
end
