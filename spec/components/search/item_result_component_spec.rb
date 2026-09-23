# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ItemResultComponent, type: :component do
  let(:component) { described_class.new(result:, pinned_object_druids:) }
  let(:result) { SearchResults::Item.new(solr_doc:, index: 2) }
  let(:pinned_object_druids) { Set.new }
  let(:solr_doc) { build(:solr_item, druid:, title:, apo_druid:) }
  let(:title) { 'Test Title' }
  let(:druid) { 'druid:bb123cd4567' }
  let(:apo_druid) { 'druid:xy987zt6543' }

  context 'with a basic item' do
    it 'renders the result' do
      render_inline(component)

      caption = page.find('table#item-result-bb123cd4567 caption')
      expect(caption).to have_css('span', text: '2.')
      expect(caption).to have_link('Test Title', href: "/objects/#{druid}?search_position=2")
      expect(caption).to have_button('Pin')

      expect(page).to have_table_value('item-result-bb123cd4567', 'Druid', 'bb123cd4567')
      expect(page).to have_css('.object-type-item .rounded-pill', text: 'Item')
      expect(find_table_value_cell('item-result-bb123cd4567', 'APO'))
        .to have_link('University Archives', href: "/objects/#{apo_druid}")
      expect(page).to have_table_value('item-result-bb123cd4567', 'Content type', 'Book')
      expect(page).to have_table_value('item-result-bb123cd4567', 'Released to', 'Not released')
      expect(page).to have_table_value('item-result-bb123cd4567', 'Access rights', 'Dark, Stanford')
      expect(find_table_value_cell('item-result-bb123cd4567', 'Old Argo'))
        .to have_link('Test Title', href: "https://argo.stanford.edu/view/#{druid}")
    end
  end

  context 'when the item is pinned' do
    let(:pinned_object_druids) { Set[druid] }

    it 'renders an unpin button beside the result title' do
      render_inline(component)

      caption = page.find('table#item-result-bb123cd4567 caption')
      expect(caption).to have_button('Unpin')
      expect(caption).to have_css('.bi-pin-fill')
    end
  end

  context 'when the result is an agreement' do
    let(:solr_doc) { build(:solr_item, :agreement, druid:, title:) }

    it 'does not render a pin button' do
      render_inline(component)

      caption = page.find('table#item-result-bb123cd4567 caption')
      expect(caption).to have_no_button('Pin')
      expect(caption).to have_no_button('Unpin')
    end
  end

  context 'when collections are present' do
    let(:solr_doc) { build(:solr_item, druid:, collection_druids:, collection_titles:) }
    let(:collection_druids) { ['druid:xy987zt6555', 'druid:xy987zt6556'] }
    let(:collection_titles) { ['Collection One', 'Collection Two'] }

    it 'renders the collection links' do
      render_inline(component)

      cell = find_table_value_cell('item-result-bb123cd4567', 'Collection')
      expect(cell).to have_link(collection_titles.first, href: "/objects/#{collection_druids.first}")
      expect(cell).to have_link(collection_titles.last, href: "/objects/#{collection_druids.last}")
    end
  end

  context 'when projects are present' do
    let(:solr_doc) { build(:solr_item, :with_projects, druid:) }

    it 'renders the project links' do
      render_inline(component)

      cell = find_table_value_cell('item-result-bb123cd4567', 'Project')
      expect(cell).to have_link('Project 1', href: '/search?projects%5B%5D=Project+1')
      expect(cell).to have_link('Project 2 : Project 2a', href: '/search?projects%5B%5D=Project+2+%3A+Project+2a')
    end
  end

  context 'when source ID is present' do
    let(:solr_doc) { build(:solr_item, druid:, source_id:) }
    let(:source_id) { 'test:source-123' }

    it 'renders the source ID' do
      render_inline(component)

      expect(page).to have_table_value('item-result-bb123cd4567', 'Source ID', source_id)
    end
  end

  context 'when a FOLIO instance HRID is present' do
    let(:solr_doc) do
      build(:solr_item, druid:, source_id:).merge(Search::Fields::CATALOG_RECORD_ID => folio_instance_hrid)
    end
    let(:source_id) { 'test:source-123' }
    let(:folio_instance_hrid) { 'a13335677' }

    it 'renders the FOLIO instance HRID' do
      render_inline(component)

      expect(page).to have_table_value('item-result-bb123cd4567', 'FOLIO Instance HRID', folio_instance_hrid)
    end
  end

  context 'when tags are present' do
    let(:tags) { ['Tag 1', 'Tag 2 : Tag 2a', 'Project : Project 1', 'Ticket : TESTREQ-1'] }
    let(:solr_doc) { build(:solr_item, druid:, tags:) }

    it 'renders links for non-project and non-ticket tags' do
      render_inline(component)

      cell = find_table_value_cell('item-result-bb123cd4567', 'Tag')
      expect(cell).to have_link('Tag 1', href: '/search?tags%5B%5D=Tag+1')
      expect(cell).to have_link('Tag 2 : Tag 2a', href: '/search?tags%5B%5D=Tag+2+%3A+Tag+2a')
      expect(cell).to have_no_link('Project : Project 1')
      expect(cell).to have_no_link('Ticket : TESTREQ-1')
    end
  end

  context 'when released_to values are present' do
    let(:solr_doc) { build(:solr_item, druid:, released_to:) }
    let(:released_to) { %w[Earthworks Searchworks] }

    it 'renders the released to values' do
      render_inline(component)

      expect(page).to have_table_value('item-result-bb123cd4567', 'Released to', 'Earthworks and Searchworks')
    end
  end

  context 'when tickets are present' do
    let(:solr_doc) { build(:solr_item, druid:, tickets:) }
    let(:tickets) { %w[ticket-001 ticket-002] }

    it 'renders the ticket links' do
      render_inline(component)

      cell = find_table_value_cell('item-result-bb123cd4567', 'Ticket')
      expect(cell).to have_link('ticket-001', href: '/search?tickets%5B%5D=ticket-001')
      expect(cell).to have_link('ticket-002', href: '/search?tickets%5B%5D=ticket-002')
    end
  end

  context 'when status is present' do
    let(:solr_doc) { build(:solr_item, druid:, status:) }
    let(:status) { 'v1 accessioned' }

    it 'renders the status' do
      render_inline(component)

      expect(page).to have_table_value('item-result-bb123cd4567', 'Status', 'v1 accessioned')
    end
  end

  context 'when workflow errors are present' do
    let(:solr_doc) { build(:solr_item, druid:, workflow_errors:) }
    let(:workflow_errors) { ['Error 1', 'Error 2'] }

    it 'renders the workflow errors' do
      render_inline(component)

      cell = find_table_value_cell('item-result-bb123cd4567', 'Errors')
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
