# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::PinnedTagsTableComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(pinned_tags:) }

  context 'when there are pinned tags' do
    let(:pinned_tags) { [build(:pinned_tag, tag: 'Project : Foo')] }

    it 'renders a row for each pinned tag' do
      render_inline(component)

      table = page.find('table[aria-label="Pinned tags"]')
      expect(table).to have_css('caption', text: 'Pinned tags')
      expect(table).to have_css('caption .bi-pin-fill')
      expect(table).to have_css('th', text: 'Tag')
      expect(table).to have_css('th', text: 'Unpin')

      row = table.find('tbody tr')
      cells = row.all('td')
      expect(cells[0]).to have_link('Project : Foo', href: search_path(tags: ['Project : Foo']))
      expect(cells[1]).to have_button('Unpin')
    end
  end

  context 'when there are no pinned tags' do
    let(:pinned_tags) { [] }

    it 'renders the empty message' do
      render_inline(component)

      expect(page).to have_text('No tags have been pinned.')
    end
  end
end
