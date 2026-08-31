# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::PinnedAposTableComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(pinned_apo_docs:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:agreement_druid) { 'druid:fg123gh4567' }

  let(:apo_doc) do
    SearchResults::Item.new(solr_doc: {
                              Search::Fields::ID => druid,
                              Search::Fields::TITLE => 'Test APO',
                              Search::Fields::AGREEMENT_DRUID => agreement_druid,
                              Search::Fields::AGREEMENT_TITLE => 'Test agreement'
                            })
  end

  context 'when there are pinned APOs' do
    let(:pinned_apo_docs) { [apo_doc] }

    it 'renders a row for each pinned APO' do
      render_inline(component)

      table = page.find('table[aria-label="Pinned APOs"]')
      expect(table).to have_css('caption', text: 'Pinned APOs')
      expect(table).to have_css('caption .bi-pin-fill')
      expect(table).to have_css('th', text: 'Title')
      expect(table).to have_css('th', text: 'Druid')
      expect(table).to have_css('th', text: 'Agreement')
      expect(table).to have_css('th', text: 'Unpin')

      row = table.find('tbody tr')
      cells = row.all('td')
      expect(cells[0]).to have_link('Test APO', href: object_path(druid:))
      expect(cells[1]).to have_text('bc123df4567')
      expect(cells[2]).to have_link('Test agreement', href: object_path(druid: agreement_druid))
      expect(cells[3]).to have_button('Unpin')
    end
  end

  context 'when a pinned APO has no agreement' do
    let(:pinned_apo_docs) { [apo_doc] }

    let(:apo_doc) do
      SearchResults::Item.new(solr_doc: {
                                Search::Fields::ID => druid,
                                Search::Fields::TITLE => 'Test APO'
                              })
    end

    it 'renders an empty agreement cell' do
      render_inline(component)

      row = page.find('table[aria-label="Pinned APOs"] tbody tr')
      cells = row.all('td')
      expect(cells[2]).to have_text('')
      expect(cells[2]).to have_no_link
    end
  end

  context 'when there are no pinned APOs' do
    let(:pinned_apo_docs) { [] }

    it 'renders the empty message' do
      render_inline(component)

      expect(page).to have_text('No APOs have been pinned.')
    end
  end
end
