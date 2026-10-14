# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show description CSV' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:invalid_token) { 'not-a-valid-token' }
  let(:cocina_object) { Cocina::Models.with_metadata(Cocina::Models.build(cocina_hash), 'abc123') }
  let(:cocina_hash) do
    {
      type: Cocina::Models::ObjectType.image,
      externalIdentifier: druid,
      version: 1,
      access: {
        view: 'world',
        download: 'world'
      },
      administrative: {
        hasAdminPolicy: 'druid:fh940mz2717'
      },
      description: {
        title: [
          {
            value: 'Show description CSV test object'
          }
        ],
        purl: 'https://purl.stanford.edu/bc123df4567',
        access: {
          digitalRepository: [
            {
              value: 'Stanford Digital Repository'
            }
          ]
        }
      },
      identification: {
        sourceId: 'foo:129'
      },
      structural: {
        contains: [
          {
            type: Cocina::Models::FileSetType.image,
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23',
            label: 'Image 1',
            version: 1,
            structural: {
              contains: [
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd',
                  label: 'Image 1 file',
                  filename: 'folder1/bc123df4567_0001.tiff',
                  version: 1,
                  hasMessageDigests: [],
                  access: {
                    view: 'world',
                    download: 'world'
                  },
                  administrative: {
                    publish: true,
                    sdrPreserve: true,
                    shelve: true
                  }
                }
              ]
            }
          }
        ]
      }
    }
  end

  before do
    sign_in(create(:user))
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
  end

  describe 'GET /objects/:druid/description_csv' do
    it 'sends the description as a CSV' do
      get "/objects/#{token}/description_csv"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('filename="bc123df4567_description.csv"')
      csv = CSV.parse(response.body, headers: true)
      expect(csv.length).to eq 1
      expect(csv.first.to_h).to include('druid' => 'bc123df4567', 'source_id' => 'foo:129',
                                        'title1.value' => 'Show description CSV test object')
    end

    context 'when the object is a collection' do
      let(:cocina_object) { build(:collection_with_metadata, id: druid, source_id: 'foo:130') }

      it 'sends the description as a CSV' do
        get "/objects/#{token}/description_csv"

        expect(response).to have_http_status(:ok)
        expect(CSV.parse(response.body, headers: true).first.to_h).to include('druid' => 'bc123df4567')
      end
    end

    context 'when the object is an admin policy' do
      let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }

      it 'returns not found' do
        get "/objects/#{token}/description_csv"

        expect(response).to have_http_status(:not_found)
      end
    end

    it 'raises when token verification fails' do
      get "/objects/#{invalid_token}/description_csv"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
