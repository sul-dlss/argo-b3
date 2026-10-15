# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'APO defaults' do
  let(:user) { create(:user, :reader) }
  let(:apo_druid) { 'druid:bc123df4567' }
  let(:cocina_object) do
    build(:admin_policy_with_metadata, id: apo_druid).new(
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431',
        hasAgreement: 'druid:hp308wm0436',
        accessTemplate: access_template
      }
    )
  end
  let(:access_template) do
    {
      view: 'location-based',
      download: 'location-based',
      location: 'm&m',
      useAndReproductionStatement: 'Property rights reside with the repository.',
      copyright: 'Copyright © Stanford University.',
      license: 'https://creativecommons.org/licenses/by/4.0/legalcode'
    }
  end

  before do
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
    sign_in(user)
  end

  context 'when the APO has defaults' do
    it 'returns the value and help text of each default' do
      get '/apo_defaults/bc123df4567'

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'use_and_reproduction_statement' => {
          'value' => 'Property rights reside with the repository.',
          'text' => 'APO default = Property rights reside with the repository.'
        },
        'copyright' => {
          'value' => 'Copyright © Stanford University.',
          'text' => 'APO default = Copyright © Stanford University.'
        },
        'license' => {
          'value' => 'https://creativecommons.org/licenses/by/4.0/legalcode',
          'text' => 'APO default = CC Attribution 4.0 International'
        },
        'view' => { 'value' => 'location-based', 'text' => 'APO default = Location Based' },
        'download' => { 'value' => 'location-based', 'text' => 'APO default = Location Based' },
        'location' => { 'value' => 'm&m', 'text' => 'APO default = Media and Microtext' }
      )
      expect(Sdr::Repository).to have_received(:find).with(druid: apo_druid)
    end
  end

  context 'when the APO does not have defaults' do
    let(:access_template) { { view: 'dark', download: 'none' } }

    it 'returns none as the help text of the missing defaults' do
      get "/apo_defaults/#{apo_druid}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'use_and_reproduction_statement' => { 'value' => nil, 'text' => 'APO default = none' },
        'copyright' => { 'value' => nil, 'text' => 'APO default = none' },
        'license' => { 'value' => nil, 'text' => 'APO default = none' },
        'view' => { 'value' => 'dark', 'text' => 'APO default = Dark' },
        'download' => { 'value' => 'none', 'text' => 'APO default = None' },
        'location' => { 'value' => nil, 'text' => 'APO default = none' }
      )
    end
  end

  context 'when the APO license is not a license option' do
    let(:access_template) { { view: 'world', download: 'world', license: 'https://cocina.sul.stanford.edu/licenses/none' } }

    it 'returns the license URI as the help text' do
      get "/apo_defaults/#{apo_druid}"

      expect(response.parsed_body['license'])
        .to eq('value' => 'https://cocina.sul.stanford.edu/licenses/none', 'text' => 'APO default = https://cocina.sul.stanford.edu/licenses/none')
    end
  end

  context 'when the user has no permissions for the APO' do
    let(:user) { create(:user) }

    it 'returns the defaults' do
      get "/apo_defaults/#{apo_druid}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['view']).to eq('value' => 'location-based', 'text' => 'APO default = Location Based')
    end
  end

  context 'when the object is not found' do
    before do
      allow(Sdr::Repository).to receive(:find).and_raise(Sdr::Repository::NotFoundResponse)
    end

    it 'returns a not found error' do
      get "/apo_defaults/#{apo_druid}"

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when the object is not an APO' do
    let(:cocina_object) { build(:dro_with_metadata, id: apo_druid) }

    it 'returns a not found error' do
      get "/apo_defaults/#{apo_druid}"

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when unauthenticated' do
    before do
      reset!
    end

    it 'redirects to login without finding the APO' do
      get "/apo_defaults/#{apo_druid}"

      expect(response).to redirect_to(login_path)
      expect(Sdr::Repository).not_to have_received(:find)
    end
  end
end
