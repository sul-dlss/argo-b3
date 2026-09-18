# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ItemQueryBuilder do
  subject(:item_query) { described_class.call(search_form:) }

  let(:user) { create(:user, :admin) }

  before { Current.effective_groups = user.groups }

  context 'with a blank search form' do
    let(:search_form) { ResultsSearchForm.new(query: '') }

    it 'builds the correct query parts' do
      result = described_class.call(search_form:)
      expect(result).to include('q.alt': '*:*', defType: 'dismax')
      expect(result).not_to have_key(:fq)
      expect(result).to have_key(:qf)
    end
  end

  context 'with a query' do
    let(:search_form) { ResultsSearchForm.new(query: 'test') }

    it 'builds the correct query parts' do
      result = described_class.call(search_form:)
      expect(result).to include(q: 'test')
    end
  end

  context 'when debug is true' do
    let(:search_form) { ResultsSearchForm.new(debug: true) }

    it 'includes debugQuery in the result' do
      result = described_class.call(search_form:)
      expect(result).to include(debugQuery: true)
    end
  end

  context 'with object types (facet filter query)' do
    let(:search_form) { ResultsSearchForm.new(object_types: %w[dro collection]) }

    it 'builds the correct filter query for object types' do
      result = described_class.call(search_form:)
      expect(Array(result[:fq])).to include("{!tag=#{Search::Fields::OBJECT_TYPES}}#{Search::Fields::OBJECT_TYPES}:(\"dro\" OR \"collection\")") # rubocop:disable Layout/LineLength
    end
  end

  context 'with access rights (facet filter query)' do
    let(:search_form) { ResultsSearchForm.new(access_rights: ['dark']) }

    it 'builds the correct filter query for access rights' do
      result = described_class.call(search_form:)
      expect(Array(result[:fq])).to include("#{Search::Fields::ACCESS_RIGHTS}:(\"dark\")")
    end
  end

  context 'with access rights exclude (facet filter query)' do
    let(:search_form) { ResultsSearchForm.new(access_rights_exclude: ['dark']) }

    it 'builds the correct filter query for access rights exclude' do
      result = described_class.call(search_form:)
      expect(Array(result[:fq])).to include("{!tag=#{Search::Fields::ACCESS_RIGHTS}}-#{Search::Fields::ACCESS_RIGHTS}:(\"dark\")")
    end
  end

  context 'with an admin policy druid (facet filter query)' do
    let(:search_form) { ResultsSearchForm.new(admin_policy_druids: ['druid:bc123df4567']) }

    it 'builds the correct filter query for the admin policy druid' do
      expect(Array(item_query[:fq])).to include(%(#{Search::Fields::APO_DRUID}:("druid:bc123df4567")))
    end
  end

  context 'with a collection druid (facet filter query)' do
    let(:search_form) { ResultsSearchForm.new(collection_druids: ['druid:bc123df4567']) }

    it 'builds the correct filter query for the collection druid' do
      expect(Array(item_query[:fq])).to include(%(#{Search::Fields::COLLECTION_DRUIDS}:("druid:bc123df4567")))
    end
  end

  context 'with released to earthworks (dynamic facet)' do
    let(:search_form) { ResultsSearchForm.new(released_to_earthworks: %w[last_year never]) }

    it 'builds the correct filter query for released to earthworks' do
      result = described_class.call(search_form:)
      expect(Array(result[:fq]))
        .to include("(#{Search::Fields::RELEASED_TO_EARTHWORKS}:[NOW-1YEAR/DAY TO *]) OR " \
                    "(-#{Search::Fields::RELEASED_TO_EARTHWORKS}:[* TO *])")
    end
  end

  context 'with earliest accessioned date (dynamic facet)' do
    context 'with from and to dates' do
      let(:search_form) do
        ResultsSearchForm.new(earliest_accessioned_date_from: '2023-01-01', earliest_accessioned_date_to: '2023-12-31')
      end

      it 'builds the correct filter query for earliest accessioned date' do
        result = described_class.call(search_form:)
        expect(Array(result[:fq]))
          .to include("#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:[2023-01-01T00:00:00Z TO 2023-12-31T23:59:59Z]")
      end
    end

    context 'with from date' do
      let(:search_form) { ResultsSearchForm.new(earliest_accessioned_date_from: '2023-01-01') }

      it 'builds the correct filter query for earliest accessioned date' do
        result = described_class.call(search_form:)
        expect(Array(result[:fq]))
          .to include("#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:[2023-01-01T00:00:00Z TO *]")
      end
    end

    context 'with to date' do
      let(:search_form) { ResultsSearchForm.new(earliest_accessioned_date_to: '2023-12-31') }

      it 'builds the correct filter query for earliest accessioned date' do
        result = described_class.call(search_form:)
        expect(Array(result[:fq]))
          .to include("#{Search::Fields::EARLIEST_ACCESSIONED_DATE}:[* TO 2023-12-31T23:59:59Z]")
      end
    end
  end
end
