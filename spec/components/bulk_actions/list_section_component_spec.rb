# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ListSectionComponent, type: :component do
  let(:component) do
    described_class.new(label: 'My bulk actions', classes: 'my-class',
                        bulk_action_configs: [BulkActions::MANAGE_RELEASE])
  end

  it 'renders the section' do
    render_inline(component)

    expect(page).to have_css('section.my-class#my-bulk-actions-bulk-actions-section h2', text: 'My bulk actions')
    within('section ul li:nth-of-type(1)') do
      expect(page).to have_link('Manage release', href: '/bulk_actions/manage_release/new')
      expect(page).to have_css('p', text: 'Adds release tags to individual objects.')
    end
  end
end
