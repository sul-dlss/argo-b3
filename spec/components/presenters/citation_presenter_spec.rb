# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CitationPresenter do
  let(:presenter) { described_class.new(result:, italicize:) }
  let(:result) do
    double(SearchResults::Item, # rubocop:disable RSpec/VerifiedDoubles
           title:,
           author:,
           publisher:,
           publication_place:,
           publication_date:)
  end
  let(:title) { 'The Great Book' }
  let(:author) { 'John Doe' }
  let(:publisher) { ['Famous Publisher'] }
  let(:publication_place) { ['New York'] }
  let(:publication_date) { '2020' }
  let(:italicize) { false }

  context 'when all fields are present and italicize is true' do
    let(:italicize) { true }

    it 'generates a full citation with italics' do
      expected_citation = 'John Doe <em>The Great Book</em>: Famous Publisher, New York, 2020'
      expect(presenter.call).to eq(expected_citation)
    end
  end

  context 'when author is missing' do
    let(:author) { nil }

    it 'generates a citation without the author' do
      expected_citation = 'The Great Book: Famous Publisher, New York, 2020'
      expect(presenter.call).to eq(expected_citation)
    end
  end

  context 'when author and title are missing' do
    let(:author) { nil }
    let(:title) { nil }

    it 'generates a citation without the author and title' do
      expected_citation = ': Famous Publisher, New York, 2020'
      expect(presenter.call).to eq(expected_citation)
    end
  end

  context 'when all fields are missing' do
    let(:author) { nil }
    let(:title) { nil }
    let(:publisher) { nil }
    let(:publication_place) { nil }
    let(:publication_date) { nil }

    it 'generates an empty citation' do
      expect(presenter.call).to eq('')
    end
  end
end
