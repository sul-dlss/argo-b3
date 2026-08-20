# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObjectReleasedPresenter do
  subject(:presenter) { described_class.new(document:, version_service:, release_tags:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:document) do
    SolrDocPresenter.new(solr_doc: { Search::Fields::ID => druid,
                                     Search::Fields::CATALOG_RECORD_ID => catalog_record_id })
  end
  let(:catalog_record_id) { [] }
  let(:version_service) { instance_double(Sdr::VersionService, version: 2, open?: false, accessioning?: false) }

  describe '#heading' do
    context 'when there are no release tags' do
      let(:release_tags) { [] }

      it 'returns the unreleased heading' do
        expect(presenter.heading).to eq(I18n.t('show.released_to.unreleased.heading'))
      end
    end

    context 'when there are release tags' do
      let(:release_tags) { [instance_double(Dor::Services::Client::ReleaseTag, to: 'Searchworks')] }

      it 'returns the released heading' do
        expect(presenter.heading).to eq(I18n.t('show.released_to.released.heading'))
      end

      context 'when the object is still undeposited' do
        let(:version_service) { instance_double(Sdr::VersionService, version: 1, open?: true, accessioning?: false) }

        it 'returns the unreleased heading' do
          expect(presenter.heading).to eq(I18n.t('show.released_to.unreleased.heading'))
        end
      end
    end
  end

  describe '#release_tag_links' do
    let(:release_tags) do
      [
        instance_double(Dor::Services::Client::ReleaseTag, to: 'Searchworks'),
        instance_double(Dor::Services::Client::ReleaseTag, to: 'Earthworks'),
        instance_double(Dor::Services::Client::ReleaseTag, to: 'PURL sitemap')
      ]
    end

    it 'returns a label and url for each release target' do
      expect(presenter.release_tag_links).to eq(
        [
          { label: 'Searchworks', url: "https://searchworks.stanford.edu/view/#{druid}" },
          { label: 'Earthworks', url: 'https://earthworks.stanford.edu/catalog/stanford-bc123df4567' },
          { label: 'PURL sitemap', url: 'https://purl.stanford.edu/bc123df4567' }
        ]
      )
    end

    context 'when the object has a folio catalog record id' do
      let(:catalog_record_id) { ['a1234567'] }

      it 'links to Searchworks using the catalog record id instead of the druid' do
        searchworks_link = presenter.release_tag_links.find { |link| link[:label] == 'Searchworks' }

        expect(searchworks_link[:url]).to eq('https://searchworks.stanford.edu/view/a1234567')
      end
    end
  end
end
