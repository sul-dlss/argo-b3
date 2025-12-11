# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Workflow grid with all scope', :solr do
  before do
    create(:solr_item, :with_workflows, title: 'Mark Twain : portrait for orchestra')
    create(:solr_item, title: 'The Adventures of Mark Twain', workflows: ['accessionWF:update-doi:error'])
    create_list(:solr_item, 3, :with_workflows)

    allow(Dor::Services::Client.workflows).to receive(:templates).and_return(['accessionWF'])
    allow(Dor::Services::Client.workflows).to receive(:template).with('accessionWF').and_return(ACCESSIONWF_TEMPLATE)
    allow(ResetWorkflowErrorsJob).to receive(:perform_later)
  end

  it 'show only items from last search in the workflow grid' do
    visit root_path

    find_search_field.fill_in(with: 'twain')
    click_button('Search')

    expect(page).to have_result_count(2)

    click_link('Workflow grid')

    expect(page).to have_field('All items', checked: false)
    expect(page).to have_field('All items including Google Books', checked: false)
    expect(page).to have_field('From last search', checked: true, disabled: false)
    expect(page).to have_content('2 items for: "twain"')

    expect(page).to have_css('table#workflow-table-accessionWF tbody tr:nth-of-type(4) td:nth-of-type(5)', text: '1')

    choose 'All items'
    click_button 'Go'

    expect(page).to have_css('table#workflow-table-accessionWF tbody tr:nth-of-type(4) td:nth-of-type(5)', text: '4')

    choose 'From last search'
    click_button 'Go'

    expect(page).to have_css('table#workflow-table-accessionWF tbody tr:nth-of-type(4) td:nth-of-type(5)', text: '1')

    # Now reset workflow errors
    within('table#workflow-table-accessionWF tbody tr:nth-of-type(7) td:nth-of-type(4)') do
      click_button 'Reset'
    end

    expect(page).to have_toast('Resetting errors for accessionWF - update-doi.')

    expect(ResetWorkflowErrorsJob).to have_received(:perform_later) do |args|
      expect(args[:workflow_name]).to eq('accessionWF')
      expect(args[:process_name]).to eq('update-doi')
      expect(args[:search_form]).to be_a(SearchForm)
      expect(args[:search_form].attributes).to match({ 'query' => 'twain', 'page' => 1 })
    end
  end
end
