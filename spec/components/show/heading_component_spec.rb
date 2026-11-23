# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::HeadingComponent, type: :component do
  subject(:component) { described_class.new(solr_doc:, pinned: false, read_only_badge:) }

  let(:solr_doc) do
    SolrDocPresenter.new(solr_doc: { Search::Fields::ID => 'druid:bc123df4567', Search::Fields::TITLE => 'My object',
                                     Search::Fields::OBJECT_TYPES => [object_type] })
  end
  let(:object_type) { 'item' }
  let(:read_only_badge) { false }

  it 'renders the object type badge, a heading of only the title, and the pin button' do
    render_inline(component)

    expect(page).to have_css('.object-type-badge', text: 'Item')
    expect(page).to have_css('h1', exact_text: 'My object')
    expect(page).to have_css('h1 ~ * button', text: 'Pin')
    expect(page).to have_no_css('.read-only-badge')
  end

  context 'when the read-only badge is requested' do
    let(:read_only_badge) { true }

    it 'renders the read only badge' do
      render_inline(component)

      expect(page).to have_css('h1 ~ .read-only-badge', text: 'Read only')
    end
  end

  context 'when the object is an agreement' do
    let(:object_type) { 'agreement' }

    it 'does not render the pin button' do
      render_inline(component)

      expect(page).to have_css('.object-type-badge', text: 'Agreement')
      expect(page).to have_no_button('Pin')
    end
  end
end
