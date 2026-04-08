# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show collection' do
  let(:druid) { 'druid:bb123cd4567' }
  let(:apo_druid) { 'druid:cc123cd4578' }

  let(:original_title) { 'My collection title' }
  let(:updated_title) { 'My updated collection title' }

  def build_presenter(title:)
    cocina_object = build(:collection_with_metadata, id: druid, admin_policy_id: apo_druid)
                    .new(
                      description: {
                        title: [{ value: title }],
                        purl: 'https://purl.stanford.edu/bb123cd4567'
                      }
                    )
    cocina_model = CocinaModels::Factory.build(cocina_object)
    CocinaModels::PresenterFactory.build(cocina_model)
  end

  before do
    allow(Sdr::TitleService).to receive(:call).with(druid: apo_druid).and_return('My APO')

    sign_in(create(:user))
  end

  it 'displays the collection' do
    presenter = build_presenter(title: original_title)
    allow(CocinaModels::PresenterFactory).to receive(:find_and_build).and_return(presenter)

    visit "/objects/#{druid}"

    expect(page).to have_css('h1', text: original_title)

    # Tabs
    expect(page).to have_css('.nav-link.active', text: 'Details')
    expect(page).to have_css('.nav-link.disabled', text: 'History')
    expect(page).to have_css('.nav-link.disabled', text: 'Events')
    expect(page).to have_css('.nav-link', text: 'Cocina Model')

    # Overview table
    expect(page).to have_css('table[id="overview-table"] caption', text: 'Overview')
    expect(page).to have_table_value('overview-table', 'Object type', 'Collection')
    within(find_table_value_cell('overview-table', 'Admin policy')) do
      expect(page).to have_link('My APO', href: "/objects/#{apo_druid}")
      expect(page).to have_link('All objects with this APO',
                                href: search_path(Search::Fields::APO_DRUID => [apo_druid]))
    end

    # Description table
    expect(page).to have_css('table[id="description-table"] caption', text: 'Description')
    expect(page).to have_table_value('description-table', 'Title', original_title)

    # Cocina model tab
    click_button 'Cocina Model'
    expect(page).to have_css('pre', text: "\"externalIdentifier\": \"#{druid}\"")
    expect(page).to have_css('pre', text: "\"value\": \"#{original_title}\"")

    presenter = build_presenter(title: updated_title)
    allow(CocinaModels::PresenterFactory).to receive(:find_and_build).and_return(presenter)

    expect(page).to have_css('h1', text: updated_title)
    expect(page).to have_css('pre', text: "\"value\": \"#{updated_title}\"")

    click_button 'Details'
    expect(page).to have_table_value('description-table', 'Title', updated_title)
  end
end
