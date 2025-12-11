# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ListSectionComponent, type: :component do
  let(:component) { described_class.new(label: 'My bulk actions', classes: 'my-class') }

  it 'renders the section' do
    render_inline(component) do |component|
      component.with_bulk_action key: :manage_release, path: '/bulk_actions/manage_release/new'
    end

    expect(page).to have_css('section.my-class#my-bulk-actions-bulk-actions-section h2', text: 'My bulk actions')
    within('section ul li:nth-of-type(1)') do
      expect(page).to have_link('Manage release', href: '/bulk_actions/manage_release/new')
      expect(page).to have_css('p', text: 'Adds release tags to individual objects.')
    end
  end
end
