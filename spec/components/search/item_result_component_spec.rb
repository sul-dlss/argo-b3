# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ItemResultComponent, type: :component do
  let(:component) { described_class.new(result:) }

  let(:result) do
    double(SearchResults::Item, # rubocop:disable RSpec/VerifiedDoubles
           title: 'Test Title',
           druid: 'druid:ab123cd4567',
           bare_druid: 'ab123cd4567',
           object_types: ['item'],
           content_types:,
           apo_druid: 'druid:xy987zt6543',
           apo_title: 'Test APO Title',
           collection_druids:,
           collection_titles:,
           projects:,
           source_id:,
           identifiers:,
           released_to:,
           tickets:,
           status:,
           workflow_errors:,
           access_rights:,
           index: 2,
           first_shelved_image:,
           author:,
           publisher:,
           publication_place:,
           publication_date:)
  end

  let(:content_types) { nil }
  let(:collection_druids) { nil }
  let(:collection_titles) { nil }
  let(:projects) { nil }
  let(:source_id) { nil }
  let(:identifiers) { nil }
  let(:released_to) { nil }
  let(:tickets) { nil }
  let(:status) { nil }
  let(:workflow_errors) { nil }
  let(:access_rights) { nil }
  let(:first_shelved_image) { nil }
  let(:author) { nil }
  let(:publisher) { nil }
  let(:publication_place) { nil }
  let(:publication_date) { nil }

  it 'renders the result' do
    render_inline(component)

    caption = page.find('table#item-result-ab123cd4567 caption')
    expect(caption).to have_css('span', text: '2.')
    expect(caption).to have_link('Test Title', href: 'https://argo.stanford.edu/view/druid:ab123cd4567')

    expect(page).to have_table_value('item-result-ab123cd4567', 'DRUID', 'druid:ab123cd4567')
    expect(page).to have_table_value('item-result-ab123cd4567', 'Object Type', 'item')
    expect(find_table_value_cell('item-result-ab123cd4567', 'Admin Policy')).to have_link('Test APO Title',
                                                                                          href: 'https://argo.stanford.edu/view/druid:xy987zt6543')
  end

  context 'when content types are present' do
    let(:content_types) { ['text'] }

    it 'renders the content types' do
      render_inline(component)

      expect(page).to have_table_value('item-result-ab123cd4567', 'Content Type', 'text')
    end
  end

  context 'when collections are present' do
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
    let(:projects) { ['Project A', 'Project B'] }

    it 'renders the project links' do
      render_inline(component)

      cell = find_table_value_cell('item-result-ab123cd4567', 'Projects')
      expect(cell).to have_link('Project A', href: '/search?projects%5B%5D=Project+A')
      expect(cell).to have_link('Project B', href: '/search?projects%5B%5D=Project+B')
    end
  end

  context 'when source ID is present' do
    let(:source_id) { 'test:source-123' }

    it 'renders the source ID' do
      render_inline(component)

      expect(page).to have_table_value('item-result-ab123cd4567', 'Source', source_id)
    end
  end

  context 'when identifiers are present' do
    let(:identifiers) { %w[test:source-123 folio:a13335677] }

    it 'renders the identifiers' do
      render_inline(component)

      expect(page).to have_table_value('item-result-ab123cd4567', 'IDs', 'test:source-123, folio:a13335677')
    end
  end

  context 'when released_to values are present' do
    let(:released_to) { %w[Earthworks Searchworks] }

    it 'renders the released to values' do
      render_inline(component)

      expect(page).to have_table_value('item-result-ab123cd4567', 'Released to', 'Earthworks and Searchworks')
    end
  end

  context 'when tickets are present' do
    let(:tickets) { %w[ticket-001 ticket-002] }

    it 'renders the ticket links' do
      render_inline(component)

      cell = find_table_value_cell('item-result-ab123cd4567', 'Tickets')
      expect(cell).to have_link('ticket-001', href: '/search?tickets%5B%5D=ticket-001')
      expect(cell).to have_link('ticket-002', href: '/search?tickets%5B%5D=ticket-002')
    end
  end

  context 'when status is present' do
    let(:status) { 'v1 accessioned' }

    it 'renders the status' do
      render_inline(component)

      expect(page).to have_table_value('item-result-ab123cd4567', 'Status', 'v1 accessioned')
    end
  end

  context 'when workflow errors are present' do
    let(:workflow_errors) { ['Error 1', 'Error 2'] }

    it 'renders the workflow errors' do
      render_inline(component)

      cell = find_table_value_cell('item-result-ab123cd4567', 'Errors')
      expect(cell).to have_css('span.text-danger', text: 'Error 1; Error 2')
    end
  end

  context 'when access rights are present' do
    let(:access_rights) { %w[dark stanford] }

    it 'renders the access rights' do
      render_inline(component)

      expect(page).to have_table_value('item-result-ab123cd4567', 'Access Rights', 'dark, stanford')
    end
  end
end
