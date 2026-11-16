# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::SearchCountComponent, type: :component do
  let(:component) { described_class.new(count:, noun: 'item', search_form:) }
  let(:search_form) { ResultsSearchForm.new(collection_druids: ['druid:bc123df4567']) }

  context 'when there are objects' do
    let(:count) { 12 }

    it 'renders a button linking to the search' do
      render_inline(component)

      expect(page).to have_link('View 12 items', href: '/search?collection_druids%5B%5D=druid%3Abc123df4567')
    end
  end

  context 'when there are no objects' do
    let(:count) { 0 }

    it 'renders the count as text' do
      render_inline(component)

      expect(page).to have_text('0 items')
      expect(page).to have_no_link
    end
  end
end
