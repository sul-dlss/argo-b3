# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::PinnedSearchesTableComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(pinned_searches:) }

  let(:search_form) { SearchForm.new(query: 'test') }

  context 'when there are pinned searches' do
    let(:pinned_searches) { [build(:pinned_search, search_form_attributes: search_form.attributes)] }

    it 'renders a row for each pinned search' do
      render_inline(component)

      table = page.find('table[aria-label="Pinned searches"]')
      expect(table).to have_css('caption', text: 'Pinned searches')
      expect(table).to have_css('caption .bi-pin-fill')
      expect(table).to have_css('th', text: 'Search')
      expect(table).to have_css('th', text: 'Unpin')

      row = table.find('tbody tr')
      cells = row.all('td')
      expect(cells[0]).to have_link(search_form.to_s, href: search_path(search_form.attributes))
      expect(cells[1]).to have_css('.bi-pin-fill')
    end
  end

  context 'when there are no pinned searches' do
    let(:pinned_searches) { [] }

    it 'renders the empty message' do
      render_inline(component)

      expect(page).to have_text('No searches have been pinned.')
    end
  end
end
