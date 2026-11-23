# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::SelectedFacetValuesBuilder do
  subject(:facet_json) { described_class.call(facet_config:, search_form:).with_indifferent_access }

  let(:facet_config) { Search::Facets::LANGUAGES }
  let(:search_form) do
    ResultsSearchForm.new(languages: ['English', Search::Facets::MISSING_VALUE],
                          languages_exclude: ['Turkish, Ottoman'])
  end

  it 'counts the selected and excluded values, ignoring the facet filters' do
    expect(facet_json).to eq(
      {
        "#{Search::Fields::LANGUAGES}-selected" => {
          type: 'query',
          q: '*:*',
          domain: { excludeTags: [Search::Fields::LANGUAGES] },
          facet: {
            '0' => { type: 'query', q: "{!term f=#{Search::Fields::LANGUAGES}}English" },
            '1' => { type: 'query', q: "{!term f=#{Search::Fields::LANGUAGES}}Turkish, Ottoman" }
          }
        }
      }.with_indifferent_access
    )
  end

  it 'reads a value back from its query' do
    q = facet_json.dig("#{Search::Fields::LANGUAGES}-selected", :facet, '1', :q)
    expect(described_class.value_from(facet_config:, query: q)).to eq('Turkish, Ottoman')
  end

  context 'when no values are selected' do
    let(:search_form) { ResultsSearchForm.new }

    it 'returns nothing' do
      expect(facet_json).to be_empty
    end
  end

  context 'when the facet is an :and facet without exclude' do
    let(:facet_config) { Search::Facets::GENRES }
    let(:search_form) { ResultsSearchForm.new(genres: ['thesis']) }

    it 'does not ignore the facet filters' do
      expect(facet_json.values.first).not_to include(:domain)
    end
  end

  context 'when the facet is composite' do
    let(:facet_config) { Search::Facets::ADMIN_POLICIES }
    let(:search_form) { ResultsSearchForm.new(admin_policy_druids: ['druid:bc123df4567']) }

    it 'facets on the composite field for the label' do
      expect(facet_json.values.first[:facet]['0']).to eq(
        {
          type: 'query',
          q: "{!term f=#{Search::Fields::APO_DRUID}}druid:bc123df4567",
          facet: { labels: { type: 'terms', field: Search::Fields::APO_TITLE_DRUID, limit: -1 } }
        }.with_indifferent_access
      )
    end
  end
end
