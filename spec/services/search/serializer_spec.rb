# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::Serializer do
  subject(:serialized_query) { described_class.call(search_form:) }

  let(:search_form) do
    ResultsSearchForm.new(query: 'test query',
                          object_types: %w[item collection],
                          content_types: ['image'],
                          access_rights_exclude: ['dark'],
                          earliest_accessioned_date: ['last_7_days'],
                          embargo_release_date: %w[next_7_days all],
                          last_accessioned_date_from: '2024-01-01',
                          last_accessioned_date_to: '2024-12-31',
                          last_opened_date_from: '2024-02-01',
                          last_published_date_to: '2024-11-30',
                          registered_date: ['last_30_days'],
                          registered_date_from: '2021-02-01',
                          registered_date_to: '2022-02-01')
  end
  let(:query) { 'test query' }

  it 'returns the query as a string' do
    expect(serialized_query)
      .to eq('"test query" AND ' \
             'Access rights: NOT "dark" AND ' \
             'Content type: "image" AND ' \
             'First deposited date: "Last 7 days" AND ' \
             'Embargo release date: ("Next 7 days" AND "All") AND ' \
             'Last deposited date: 2024-01-01 TO 2024-12-31 AND ' \
             'Last draft opened date: 2024-02-01 TO * AND ' \
             'Last published date: * TO 2024-11-30 AND ' \
             'Object type: ("item" OR "collection") AND ' \
             'Registered date: ("Last 30 days" AND 2021-02-01 TO 2022-02-01)')
  end

  context 'with languages combined with And and excluded languages' do
    let(:search_form) do
      ResultsSearchForm.new(languages: %w[English Spanish], languages_exclude: %w[French German],
                            languages_operator: 'and')
    end

    it 'joins the selected languages with AND and the excluded languages with OR' do
      expect(serialized_query)
        .to eq('Language: ("English" AND "Spanish") AND Language: NOT ("French" OR "German")')
    end
  end

  context 'with a missing value' do
    let(:search_form) { ResultsSearchForm.new(languages: %w[English _missing_value]) }

    it 'labels the missing value as No value' do
      expect(serialized_query).to eq('Language: ("English" OR "No value")')
    end
  end

  context 'with an agreement' do
    let(:search_form) { ResultsSearchForm.new(agreement_druids: ['druid:bc123df4567']) }

    it 'includes the agreement' do
      expect(serialized_query).to eq('Agreement: "druid:bc123df4567"')
    end
  end

  context 'with an advanced search' do
    let(:search_form) { ResultsSearchForm.new(advanced: true, query: '"Miller Library" OR octopus') }

    it 'labels the query as an advanced search' do
      expect(serialized_query).to eq('Advanced search ❯ "Miller Library" OR octopus')
    end
  end

  context 'with an advanced search and facets' do
    let(:search_form) do
      ResultsSearchForm.new(advanced: true, query: '"Miller Library" OR octopus', content_types: ['image'])
    end

    it 'groups the query so that its operators are kept apart from the facets' do
      expect(serialized_query).to eq('Advanced search ❯ ("Miller Library" OR octopus) AND Content type: "image"')
    end
  end

  context 'with Multi-Item Deposits' do
    let(:search_form) { WorkflowGridSearchForm.new(query: 'maps', multi_item_deposit_action_ids: %w[12 13]) }

    it 'includes the Multi-Item Deposits' do
      expect(serialized_query).to eq('"maps" AND Multi-item deposit: 12 AND Multi-item deposit: 13')
    end
  end
end
