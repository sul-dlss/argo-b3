# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Object versions' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, find: cocina_object) }
  let(:cocina_object) { Cocina::Models.with_metadata(Cocina::Models.build(cocina_hash), 'current-lock') }
  let(:cocina_hash) do
    {
      type: Cocina::Models::ObjectType.image,
      externalIdentifier: druid,
      version: 2,
      access: { view: 'world', download: 'world' },
      administrative: { hasAdminPolicy: 'druid:fh940mz2717' },
      description: { title: [{ value: 'Version 2 title' }], purl: 'https://purl.stanford.edu/bc123df4567' },
      identification: { sourceId: 'foo:129' },
      structural: {
        contains: [
          {
            type: Cocina::Models::FileSetType.image,
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23',
            label: 'Image 1',
            version: 2,
            structural: {
              contains: [
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd',
                  label: 'Image 1 file',
                  filename: 'bc123df4567_0001.tiff',
                  version: 2,
                  hasMessageDigests: [],
                  access: { view: 'world', download: 'world' },
                  administrative: { publish: true, sdrPreserve: true, shelve: true }
                }
              ]
            }
          }
        ]
      }
    }
  end
  let(:invalid_cocina) do
    Dor::Services::Client::InvalidCocina.new(externalIdentifier: druid, description: { title: 'not valid', note: [] },
                                             error_message: 'title is not an array')
  end

  before do
    sign_in(create(:user))
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  describe 'GET /objects/:object_druid/versions/:version/cocina' do
    it 'renders the cocina for the version as JSON without blanks' do
      get "/objects/#{token}/versions/2/cocina"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      json = response.parsed_body
      expect(json).to include('externalIdentifier' => druid, 'version' => 2)
      expect(json).not_to have_key('lock')
      expect(json['description']).not_to have_key('note')
      expect(json['structural']['contains'].first['label']).to eq('Image 1')
      expect(version_client).to have_received(:find).with('2')
    end

    context 'when the cocina is invalid' do
      let(:cocina_object) { invalid_cocina }

      it 'renders the stored JSON without the error message or blanks' do
        get "/objects/#{token}/versions/2/cocina"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('externalIdentifier' => druid, 'description' => { 'title' => 'not valid' })
      end
    end

    it 'returns forbidden when token verification fails' do
      get '/objects/not-a-valid-token/versions/2/cocina'

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /objects/:object_druid/versions/:version/structural_csv' do
    it 'sends the structural metadata for the version as a CSV' do
      get "/objects/#{token}/versions/2/structural_csv"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('filename="bc123df4567_v2_structural.csv"')
      csv = CSV.parse(response.body, headers: true)
      expect(csv.first.to_h).to include('druid' => 'bc123df4567', 'resource_label' => 'Image 1',
                                        'filename' => 'bc123df4567_0001.tiff')
      expect(Content.count).to eq(0)
    end

    context 'when the cocina is invalid' do
      let(:cocina_object) { invalid_cocina }

      it 'redirects to the object page with an alert' do
        get "/objects/#{token}/versions/2/structural_csv"

        expect(response).to redirect_to('/objects/druid:bc123df4567')
        expect(flash[:danger]).to eq('Cocina is not valid, so cannot generate structural metadata CSV.')
      end
    end
  end

  describe 'GET /objects/:object_druid/versions/:version/descriptive_csv' do
    it 'sends the descriptive metadata for the version as a CSV' do
      get "/objects/#{token}/versions/2/descriptive_csv"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('filename="bc123df4567_v2_description.csv"')
      csv = CSV.parse(response.body, headers: true)
      expect(csv.first.to_h).to include('druid' => 'bc123df4567', 'source_id' => 'foo:129',
                                        'title1.value' => 'Version 2 title')
    end

    context 'when the cocina is invalid' do
      let(:cocina_object) { invalid_cocina }

      it 'redirects to the object page with an alert' do
        get "/objects/#{token}/versions/2/descriptive_csv"

        expect(response).to redirect_to('/objects/druid:bc123df4567')
        expect(flash[:danger]).to eq('Cocina is not valid, so cannot generate descriptive metadata CSV.')
      end
    end
  end
end
