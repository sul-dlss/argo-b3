# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show constituents' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:invalid_token) { 'not-a-valid-token' }
  let(:first_constituent_druid) { 'druid:jh330cm3013' }
  let(:second_constituent_druid) { 'druid:mn667qr8901' }
  let(:cocina_object) { Cocina::Models.with_metadata(Cocina::Models.build(cocina_hash), 'abc123') }
  let(:cocina_hash) do
    {
      type: Cocina::Models::ObjectType.object,
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
            value: 'Show constituents test object'
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
        hasMemberOrders: [
          {
            members: [first_constituent_druid, second_constituent_druid]
          }
        ]
      }
    }
  end

  let(:restricted_apo_druid) { 'druid:fh940mz2717' }

  before do
    sign_in(create(:user, :reader))
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Searchers::ItemByDruid).to receive(:call).and_return(
      [
        SearchResults::Item.new(solr_doc: { Search::Fields::ID => first_constituent_druid,
                                            Search::Fields::TITLE => 'Constituent one' }),
        SearchResults::Item.new(solr_doc: { Search::Fields::ID => second_constituent_druid,
                                            Search::Fields::TITLE => 'Constituent two',
                                            Search::Fields::APO_DRUID => restricted_apo_druid })
      ]
    )
    create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
  end

  describe 'GET /objects/:druid/constituents' do
    it 'renders a row for every constituent, in member order, but only links viewable ones' do
      get "/objects/#{token}/constituents"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Constituent one')
      expect(response.body).to include('Constituent two')
      expect(response.body).to include('jh330cm3013')
      expect(response.body).to include('mn667qr8901')
      expect(Searchers::ItemByDruid).to have_received(:call).with(
        druids: [first_constituent_druid, second_constituent_druid],
        user_scope: nil,
        fields: anything
      )
      expect(response.body).to include("href=\"/objects/#{first_constituent_druid}\"")
      expect(response.body).not_to include("href=\"/objects/#{second_constituent_druid}\"")
    end

    it 'raises when token verification fails' do
      get "/objects/#{invalid_token}/constituents"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
