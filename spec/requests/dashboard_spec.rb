# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }

  before do
    sign_in(user)
  end

  it 'renders the dashboard' do
    get root_path

    expect(response).to have_http_status(:ok)
  end

  context 'when objects have recently been viewed' do
    let(:recent_object_druids) do
      %w[
        druid:bc123df4567
        druid:cd234fg5678
        druid:df345hj6789
      ]
    end
    let(:version_service) do
      instance_double(Sdr::VersionService, accessioning?: false, closed?: false, open?: true, version: 1)
    end
    let(:solr_doc_for) do
      lambda do |object_druid|
        {
          Search::Fields::ID => object_druid,
          Search::Fields::TITLE => "Title #{DruidSupport.bare_druid_from(object_druid)}",
          Search::Fields::OBJECT_TYPES => ['item'],
          Search::Fields::CONTENT_TYPES => ['book'],
          Search::Fields::OTHER_TAGS => [],
          Search::Fields::WORKFLOW_ERRORS => []
        }
      end
    end

    before do
      allow(Sdr::Repository).to receive(:lock) { |druid:| "lock-#{druid}" }
      allow(Sdr::Repository).to receive(:find_solr) { |druid:| solr_doc_for.call(druid) }
      allow(Sdr::Repository).to receive(:find) { |druid:| build(:dro_with_metadata, id: druid) }
      allow(Sdr::Repository).to receive(:release_tags).and_return([])
      allow(Sdr::VersionService).to receive(:new).and_return(version_service)
      allow(Searchers::ItemByDruid).to receive(:call).and_return(
        [recent_object_druids.first, recent_object_druids.last].map do |recent_object_druid|
          SearchResults::Item.new(solr_doc: solr_doc_for.call(recent_object_druid))
        end
      )
    end

    it 'displays available objects in most-recently-viewed order' do
      recent_object_druids.each { |recent_object_druid| get object_path(recent_object_druid) }

      get root_path

      newest_title = "Title #{DruidSupport.bare_druid_from(recent_object_druids.last)}"
      oldest_title = "Title #{DruidSupport.bare_druid_from(recent_object_druids.first)}"
      missing_title = "Title #{DruidSupport.bare_druid_from(recent_object_druids.second)}"
      expect(response.body.index(newest_title)).to be < response.body.index(oldest_title)
      expect(response.body).not_to include(missing_title)
      expect(Searchers::ItemByDruid).to have_received(:call).with(
        druids: recent_object_druids.reverse,
        fields: DashboardController::RECENT_OBJECT_FIELDS
      )
    end
  end

  describe 'POST /go_to_druid' do
    before do
      allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_return({})
    end

    it 'redirects to the object when given a prefixed druid' do
      post go_to_druid_path, params: { go_to_druid: { druid: } }

      expect(response).to redirect_to(object_path(druid))
      expect(Sdr::Repository).to have_received(:find_solr).with(druid:)
    end

    it 'redirects to the object when given an unprefixed druid' do
      post go_to_druid_path, params: { go_to_druid: { druid: 'bc123df4567' } }

      expect(response).to redirect_to(object_path(druid))
      expect(Sdr::Repository).to have_received(:find_solr).with(druid:)
    end

    context 'when the druid does not exist' do
      before do
        allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_raise(Sdr::Repository::NotFoundResponse)
      end

      it 'renders a validation error' do
        post go_to_druid_path, params: { go_to_druid: { druid: } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('does not exist')
      end
    end

    context 'when the druid is invalid' do
      it 'renders a validation error without looking up the object' do
        post go_to_druid_path, params: { go_to_druid: { druid: 'not-a-druid' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('is not a valid druid')
        expect(Sdr::Repository).not_to have_received(:find_solr)
      end
    end
  end
end
