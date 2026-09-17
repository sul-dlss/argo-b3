# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Workflow grid as a view of the current search', :solr do
  let(:user) { create(:user, :reader) }

  before do
    create(:solr_item, :with_workflows, title: 'Mark Twain : portrait for orchestra')
    create(:solr_item, title: 'The Adventures of Mark Twain', workflows: ['accessionWF:update-doi:error'])
    create_list(:solr_item, 3, :with_workflows)
    sign_in(user)

    allow(Dor::Services::Client.workflows).to receive(:templates).and_return(['accessionWF'])
    allow(Dor::Services::Client.workflows).to receive(:template).with('accessionWF').and_return(ACCESSIONWF_TEMPLATE)
    allow(ResetWorkflowErrorsJob).to receive(:perform_later)
  end

  it 'toggles between views, keeps the search, and can be refined further' do
    visit search_path

    find_search_field.fill_in(with: 'twain')
    click_button('Search')

    expect(page).to have_result_count(2)
    expect(page).to have_link('Search results view', class: 'active')

    click_link('Workflow status view')

    # The grid counts only the objects matching the search, and the search is still displayed.
    expect(page).to have_link('Workflow status view', class: 'active')
    expect(page).to have_css('.selected-item-label', text: 'twain')
    expect(page).to have_css('table#workflow-table-accessionWF tbody tr:nth-of-type(4) td:nth-of-type(5)', text: '1')

    # Pinning is not offered on the grid.
    expect(page).to have_no_button('Pin search')

    # The search can be refined from the grid, just as it can from the results. Object types is a
    # non-lazy facet, whose counts the grid gets from the secondary facets request.
    find_facet_section('Object types').click
    expect(page).to have_facet_value('item', facet: 'Object types')

    within(find_facet_section('Object types')) do
      check('item')
      click_button('Filter')
    end

    # Refining keeps the user on the grid.
    expect(page).to have_link('Workflow status view', class: 'active')
    expect(page).to have_current_filter('Object types', 'item')
    expect(page).to have_css('.selected-item-label', text: 'twain')

    # Toggling back returns to the results for the same, refined search.
    click_link('Search results view')

    expect(page).to have_link('Search results view', class: 'active')
    expect(page).to have_result_count(2)
    expect(page).to have_current_filter('Object types', 'item')
    expect(page).to have_css('.selected-item-label', text: 'twain')
  end

  it 'resets workflow errors for the objects matching the current search' do
    visit search_path

    find_search_field.fill_in(with: 'twain')
    click_button('Search')

    expect(page).to have_result_count(2)

    click_link('Workflow status view')

    within('table#workflow-table-accessionWF tbody tr:nth-of-type(7) td:nth-of-type(4)') do
      click_button 'Reset'
    end

    expect(page).to have_toast('Resetting errors for accessionWF - update-doi.')

    expect(ResetWorkflowErrorsJob).to have_received(:perform_later) do |args|
      expect(args[:workflow_name]).to eq('accessionWF')
      expect(args[:process_name]).to eq('update-doi')
      expect(args[:effective_groups]).to eq(user.groups)
      expect(args[:search_form]).to be_a(WorkflowGridSearchForm)
      expect(args[:search_form].attributes).to match({ 'query' => 'twain' })
    end
  end
end
