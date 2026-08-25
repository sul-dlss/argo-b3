# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pin::PinnedSearchComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:search_form) { SearchForm.new(query: 'test') }

  context 'when not pinned' do
    let(:component) { described_class.new(search_form:, pinned: false) }

    it 'renders a button that pins the search' do
      render_inline(component)

      expect(page).to have_css('.bi-pin')
      expect(page).to have_no_css('.bi-pin-fill')
      expect(page).to have_css("form[action='#{pinned_searches_path}'][method='post']")
      expect(page).to have_field('query', type: 'hidden', with: 'test')
      expect(page).to have_button('Pin')
    end
  end

  context 'when pinned' do
    let(:component) { described_class.new(search_form:, pinned: true) }

    it 'renders a button that unpins the search' do
      render_inline(component)

      expect(page).to have_css('.bi-pin-fill')
      expect(page).to have_no_css('.bi-pin')
      expect(page).to have_css("form[action='#{pinned_search_path(PinnedSearch.md5_for(search_form.attributes))}']")
      expect(page).to have_field('_method', type: 'hidden', with: 'delete')
      expect(page).to have_button('Unpin')
    end
  end
end
