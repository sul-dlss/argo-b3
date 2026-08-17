# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Workflow grid with all scope', :solr do
  before do
    create_list(:solr_item, 3, :with_workflows)
    sign_in(create(:user))

    allow(Dor::Services::Client.workflows).to receive(:templates).and_return(['accessionWF'])
    allow(Dor::Services::Client.workflows).to receive(:template).with('accessionWF').and_return(ACCESSIONWF_TEMPLATE)
  end

  it 'show all items in the workflow grid' do
    # Note that there is no last search cookie set in this test
    visit workflow_grid_path

    expect(page).to have_field('All items', checked: true)
    expect(page).to have_field('From last search', checked: false, disabled: true)

    within 'table#workflow-table-accessionWF' do
      rows = page.all('tbody tr')
      expect(rows.size).to eq 12
      shelve_row = rows[3]
      expect(shelve_row).to have_css('td:nth-of-type(5)', text: '3')
    end
  end
end
