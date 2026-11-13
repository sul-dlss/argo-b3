# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ListSectionComponent, type: :component do
  let(:component) do
    described_class.new(label: 'My bulk actions', classes: 'my-class',
                        bulk_action_configs: [BulkActions::REINDEX, BulkActions::EXPORT_MODS])
  end

  it 'renders the section' do
    render_inline(component)

    expect(page).to have_css('section.my-class#my-bulk-actions-bulk-actions-section h2', text: 'My bulk actions')
    reindex_li = page.find('section ul li:nth-of-type(1)')
    expect(reindex_li).to have_link('Reindex', href: '/bulk_actions/reindex/new')
    expect(reindex_li).to have_css('p', text: 'Reindex objects in Solr.')

    export_mods_li = page.find('section ul li:nth-of-type(2)')
    expect(export_mods_li).to have_link('Download descriptive metadata as MODS XML',
                                        href: '/bulk_actions/export_mods/new')
    expect(export_mods_li).to have_no_css('p')
  end
end
