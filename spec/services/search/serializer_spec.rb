# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::Serializer do
  subject(:serialized_query) { described_class.call(search_form:) }

  let(:search_form) do
    ResultsSearchForm.new(query: 'test query',
                          object_types: %w[item collection],
                          content_types: ['image'],
                          access_rights_exclude: ['dark'],
                          earliest_accessioned_date: ['last_week'],
                          embargo_release_date: %w[last_day all],
                          last_accessioned_date_from: '2024-01-01',
                          last_accessioned_date_to: '2024-12-31',
                          last_opened_date_from: '2024-02-01',
                          last_published_date_to: '2024-11-30',
                          registered_date: ['last_month'],
                          registered_date_from: '2021-02-01',
                          registered_date_to: '2022-02-01')
  end
  let(:query) { 'test query' }

  it 'returns the query as a string' do
    expect(serialized_query)
      .to eq('"test query" AND ' \
             'Access rights: NOT "dark" AND ' \
             'Content types: "image" AND ' \
             'Earliest accessioned: "Last week" AND ' \
             'Embargo release date: ("Last day" AND "All") AND ' \
             'Last accessioned date: 2024-01-01 TO 2024-12-31 AND ' \
             'Last opened date: 2024-02-01 TO * AND ' \
             'Last published date: * TO 2024-11-30 AND ' \
             'Object types: ("item" AND "collection") AND ' \
             'Registered date: ("Last month" AND 2021-02-01 TO 2022-02-01)')
  end
end
