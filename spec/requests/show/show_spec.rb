# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object' do
  let(:druid) { 'druid:bc123df4567' }
  let(:version_service) do
    instance_double(Sdr::VersionService, accessioning?: false, closed?: false, open?: true, version: 1)
  end

  before do
    sign_in(create(:user))
  end

  describe 'GET /objects/:druid' do
    context 'when the object is not found' do
      before do
        allow(Sdr::Repository).to receive(:lock).with(druid:).and_return('v1')
        allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_raise(Sdr::Repository::NotFoundResponse)
      end

      it 'renders a 404' do
        get "/objects/#{druid}"

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the object is found' do
      let(:druids) do
        %w[
          druid:bc123df4567
          druid:cd234fg5678
          druid:df345hj6789
          druid:fg456jk7890
          druid:gh567km8901
          druid:hj678np9012
        ]
      end

      before do
        allow(Sdr::Repository).to receive(:lock) { |druid:| "lock-#{druid}" }
        allow(Sdr::Repository).to receive(:find_solr) { |druid:| solr_doc(druid) }
        allow(Sdr::Repository).to receive(:find) { |druid:| build(:dro_with_metadata, id: druid) }
        allow(Sdr::Repository).to receive(:release_tags).and_return([])
        allow(Sdr::VersionService).to receive(:new).and_return(version_service)
        allow(Searchers::ItemByDruid).to receive(:call) do |druids:, **|
          druids.map { |recent_druid| SearchResults::Item.new(solr_doc: solr_doc(recent_druid)) }
        end
      end

      it 'keeps the five most recently shown unique objects and displays them in order' do
        druids.each { |recent_druid| get object_path(recent_druid) }

        expect(session[:recent_object_druids]).to eq(druids.last(5).reverse)

        get object_path(druids[3])

        expect(session[:recent_object_druids]).to eq([druids[3], druids[5], druids[4], druids[2], druids[1]])

        get root_path

        expect(response.body.index(title_for(druids[3]))).to be < response.body.index(title_for(druids[5]))
        expect(Searchers::ItemByDruid).to have_received(:call).with(
          druids: session[:recent_object_druids], fields: DashboardController::RECENT_OBJECT_FIELDS
        )
      end

      it 'does not track Turbo prefetch requests' do
        get object_path(druid), headers: { 'X-Sec-Purpose' => 'prefetch' }

        expect(session[:recent_object_druids]).to be_nil
      end

      def solr_doc(recent_druid)
        {
          Search::Fields::ID => recent_druid,
          Search::Fields::TITLE => title_for(recent_druid),
          Search::Fields::OBJECT_TYPES => ['item'],
          Search::Fields::CONTENT_TYPES => ['book'],
          Search::Fields::OTHER_TAGS => ["Project : #{DruidSupport.bare_druid_from(recent_druid)}"],
          Search::Fields::WORKFLOW_ERRORS => []
        }
      end

      def title_for(recent_druid)
        "Title #{DruidSupport.bare_druid_from(recent_druid)}"
      end
    end
  end
end
