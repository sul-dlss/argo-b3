# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Workflow grid without a search', :solr do
  before do
    create_list(:solr_item, 3, :with_workflows)
    sign_in(create(:user, :reader))

    allow(Dor::Services::Client.workflows).to receive(:templates).and_return(['accessionWF'])
    allow(Dor::Services::Client.workflows).to receive(:template).with('accessionWF').and_return(ACCESSIONWF_TEMPLATE)
  end

  it 'shows all items in the workflow grid' do
    visit workflow_grid_path

    expect(page).to have_link('Workflow status view', class: 'active')
    expect(page).to have_link('Search results view')

    within 'table#workflow-table-accessionWF' do
      rows = page.all('tbody tr')
      expect(rows.size).to eq 12
      shelve_row = rows[3]
      expect(shelve_row).to have_css('td:nth-of-type(5)', text: '3')
    end
  end
end
