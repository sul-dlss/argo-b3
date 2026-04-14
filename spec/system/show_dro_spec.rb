# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show DRO' do
  let(:druid) { 'druid:bb123cd4567' }
  let(:apo_druid) { 'druid:cc123cd4578' }
  let(:collection_druid) { 'druid:dd123cd4589' }

  let(:original_title)  { 'My title' }
  let(:updated_title)   { 'My updated title' }

  def build_solr_doc(title:)
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['item'],
      Search::Fields::TITLE => title,
      Search::Fields::APO_DRUID => [apo_druid],
      Search::Fields::APO_TITLE => ['My APO'],
      Search::Fields::COLLECTION_DRUIDS => [collection_druid],
      Search::Fields::COLLECTION_TITLES => ['My Collection']
    }
  end

  def build_cocina_object(title:)
    build(:dro_with_metadata, id: druid, admin_policy_id: apo_druid)
      .new(
        structural: { isMemberOf: [collection_druid] },
        description: {
          title: [{ value: title }],
          purl: 'https://purl.stanford.edu/bb123cd4567'
        }
      )
  end

  before do
    sign_in(create(:user))
    set_last_search_cookie
  end

  it 'displays the object' do
    # Defining the solr doc and cocina object inline because going to change the title to test refresh.
    allow(Sdr::Repository).to receive(:find_solr).and_return(build_solr_doc(title: original_title))
    allow(Sdr::Repository).to receive(:find).and_return(build_cocina_object(title: original_title))

    visit "/objects/#{druid}"

    expect(page).to have_css('h1', text: original_title)

    expect(page).to have_link('← Back to search', href: /search\?page=5&query=test/)

    # Tabs
    expect(page).to have_css('.nav-link.active', text: 'Details')
    expect(page).to have_css('.nav-link.disabled', text: 'History')
    expect(page).to have_css('.nav-link.disabled', text: 'Events')
    expect(page).to have_css('.nav-link.disabled', text: 'Content')
    expect(page).to have_css('.nav-link.disabled', text: 'Technical metadata')
    expect(page).to have_css('.nav-link', text: 'Cocina Model')

    # Overview table
    expect(page).to have_css('table[id="overview-table"] caption', text: 'Overview')
    expect(page).to have_table_value('overview-table', 'Object type', 'Item')
    within(find_table_value_cell('overview-table', 'Admin policy')) do
      expect(page).to have_link('My APO', href: "/objects/#{apo_druid}")
      expect(page).to have_link('All objects with this APO',
                                href: '/search?admin_policy_titles%5B%5D=My+APO&page=1')
    end
    within(find_table_value_cell('overview-table', 'Collection')) do
      expect(page).to have_link('My Collection', href: "/objects/#{collection_druid}")
      expect(page).to have_link('All objects with this collection',
                                href: '/search?collection_titles%5B%5D=My+Collection&page=1')
    end

    # Description table
    expect(page).to have_css('table[id="description-table"] caption', text: 'Description')
    expect(page).to have_table_value('description-table', 'Title', original_title)

    # Cocina model tab
    click_button 'Cocina Model'
    expect(page).to have_css('pre', text: "\"externalIdentifier\": \"#{druid}\"")
    expect(page).to have_css('pre', text: "\"value\": \"#{original_title}\"")

    allow(Sdr::Repository).to receive(:find_solr).and_return(build_solr_doc(title: updated_title))
    allow(Sdr::Repository).to receive(:find).and_return(build_cocina_object(title: updated_title))

    expect(page).to have_css('h1', text: updated_title)
    expect(page).to have_css('pre', text: "\"value\": \"#{updated_title}\"")

    click_button 'Details'
    expect(page).to have_table_value('description-table', 'Title', updated_title)
  end
end
