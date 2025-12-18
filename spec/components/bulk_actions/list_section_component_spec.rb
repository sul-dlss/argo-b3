# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ListSectionComponent, type: :component do
  let(:component) do
    described_class.new(label: 'My bulk actions', classes: 'my-class',
                        bulk_action_configs: [BulkActions::REINDEX, test_bulk_action_config])
  end

  let(:test_bulk_action_config) do
    # Does not have a path helper to test that case
    BulkActions::Config.new(
      label: 'Test',
      help_text: 'This is a test bulk action.'
    )
  end

  it 'renders the section' do
    render_inline(component)

    expect(page).to have_css('section.my-class#my-bulk-actions-bulk-actions-section h2', text: 'My bulk actions')
    reindex_li = page.find('section ul li:nth-of-type(1)')
    expect(reindex_li).to have_link('Reindex', href: '/bulk_actions/reindex/new')
    expect(reindex_li).to have_css('p', text: 'Reindexes the DOR object in Solr.')

    test_li = page.find('section ul li:nth-of-type(2)')
    expect(test_li).to have_css('span', text: 'Test')
    expect(test_li).to have_no_link('Test')
    expect(test_li).to have_css('p', text: 'This is a test bulk action.')
  end
end
