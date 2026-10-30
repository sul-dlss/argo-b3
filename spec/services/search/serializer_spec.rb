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

  context 'with a missing value' do
    let(:search_form) { ResultsSearchForm.new(languages: %w[English _missing_value]) }

    it 'labels the missing value as No value' do
      expect(serialized_query).to eq('Language: ("English" AND "No value")')
    end
  end

  context 'with Multi-Item Deposits' do
    let(:search_form) { WorkflowGridSearchForm.new(query: 'maps', multi_item_deposit_action_ids: %w[12 13]) }

    it 'includes the Multi-Item Deposits' do
      expect(serialized_query).to eq('"maps" AND Multi-item deposit: 12 AND Multi-item deposit: 13')
    end
  end
end
