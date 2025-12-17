# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ItemResultComponent, type: :component do
  let(:component) { described_class.new(result:) }
  let(:result) { SearchResults::Item.new(solr_doc:, index: 2) }
  let(:solr_doc) { build(:solr_item, druid:, title:, apo_druid:) }
  let(:title) { 'Test Title' }
  let(:druid) { 'druid:ab123cd4567' }
  let(:apo_druid) { 'druid:xy987zt6543' }

  context 'with a basic item' do
    it 'renders the result' do
      render_inline(component)

      caption = page.find('table#item-result-ab123cd4567 caption')
      expect(caption).to have_css('span', text: '2.')
      expect(caption).to have_link('Test Title', href: 'https://argo.stanford.edu/view/druid:ab123cd4567')

      expect(page).to have_table_value('item-result-ab123cd4567', 'DRUID', 'druid:ab123cd4567')
      expect(page).to have_table_value('item-result-ab123cd4567', 'Object Type', 'item')
      expect(find_table_value_cell('item-result-ab123cd4567', 'Admin Policy')).to have_link('University Archives',
                                                                                            href: 'https://argo.stanford.edu/view/druid:xy987zt6543')
      expect(page).to have_css "svg[aria-label='Placeholder: Responsive image']", text: 'Test Title'
      expect(page).to have_table_value('item-result-ab123cd4567', 'Content Type', 'book')
      expect(page).to have_table_value('item-result-ab123cd4567', 'Access Rights', 'dark, stanford')
    end
  end

  context 'when collections are present' do
    let(:solr_doc) { build(:solr_item, druid:, collection_druids:, collection_titles:) }
    let(:collection_druids) { ['druid:xy987zt6555', 'druid:xy987zt6556'] }
    let(:collection_titles) { ['Collection One', 'Collection Two'] }

    it 'renders the collection links' do
      render_inline(component)

      cell = find_table_value_cell('item-result-ab123cd4567', 'Collections')
      expect(cell).to have_link('Collection One', href: 'https://argo.stanford.edu/view/druid:xy987zt6555')
      expect(cell).to have_link('Collection Two', href: 'https://argo.stanford.edu/view/druid:xy987zt6556')
    end
  end

  context 'when projects are present' do
    let(:solr_doc) { build(:solr_item, :with_projects, druid:) }

    it 'renders the project links' do
      render_inline(component)

      cell = find_table_value_cell('item-result-ab123cd4567', 'Projects')
      expect(cell).to have_link('Project 1', href: '/search?projects%5B%5D=Project+1')
      expect(cell).to have_link('Project 2 : Project 2a', href: '/search?projects%5B%5D=Project+2+%3A+Project+2a')
    end
  end

  context 'when source ID is present' do
    let(:solr_doc) { build(:solr_item, druid:, source_id:) }
    let(:source_id) { 'test:source-123' }

    it 'renders the source ID' do
      render_inline(component)

      expect(page).to have_table_value('item-result-ab123cd4567', 'Source', source_id)
    end
  end

  context 'when identifiers are present' do
    let(:solr_doc) { build(:solr_item, druid:, identifiers:) }
    let(:identifiers) { %w[test:source-123 folio:a13335677] }

    it 'renders the identifiers' do
      render_inline(component)

      expect(page).to have_table_value('item-result-ab123cd4567', 'IDs', 'test:source-123, folio:a13335677')
    end
  end

  context 'when released_to values are present' do
    let(:solr_doc) { build(:solr_item, druid:, released_to:) }
    let(:released_to) { %w[Earthworks Searchworks] }

    it 'renders the released to values' do
      render_inline(component)

      expect(page).to have_table_value('item-result-ab123cd4567', 'Released to', 'Earthworks and Searchworks')
    end
  end

  context 'when tickets are present' do
    let(:solr_doc) { build(:solr_item, druid:, tickets:) }
    let(:tickets) { %w[ticket-001 ticket-002] }

    it 'renders the ticket links' do
      render_inline(component)

      cell = find_table_value_cell('item-result-ab123cd4567', 'Tickets')
      expect(cell).to have_link('ticket-001', href: '/search?tickets%5B%5D=ticket-001')
      expect(cell).to have_link('ticket-002', href: '/search?tickets%5B%5D=ticket-002')
    end
  end

  context 'when status is present' do
    let(:solr_doc) { build(:solr_item, druid:, status:) }
    let(:status) { 'v1 accessioned' }

    it 'renders the status' do
      render_inline(component)

      expect(page).to have_table_value('item-result-ab123cd4567', 'Status', 'v1 accessioned')
    end
  end

  context 'when workflow errors are present' do
    let(:solr_doc) { build(:solr_item, druid:, workflow_errors:) }
    let(:workflow_errors) { ['Error 1', 'Error 2'] }

    it 'renders the workflow errors' do
      render_inline(component)

      cell = find_table_value_cell('item-result-ab123cd4567', 'Errors')
      expect(cell).to have_css('span.text-danger', text: 'Error 1; Error 2')
    end
  end

  context 'with a thumbnail_url is present' do
    let(:solr_doc) { build(:solr_item, druid:, title:, first_shelved_image:) }
    let(:first_shelved_image) { 'default.jpg' }

    it 'renders the thumbnail' do
      render_inline(component)
      expect(page).to have_css "img[src*='default/full/!400,400/0/default.jpg']"
      expect(page).to have_css "img[alt='']"
    end
  end
end
