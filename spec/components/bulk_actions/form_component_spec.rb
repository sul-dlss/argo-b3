# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::FormComponent, type: :component do
  let(:component) { described_class.new(form:, bulk_action_config: BulkActions::REINDEX) }

  let(:form) { ActionView::Helpers::FormBuilder.new(nil, BulkActions::ReindexForm.new, vc_test_view_context, {}) }

  it 'renders the bulk action form' do
    render_inline(component)

    expect(page).to have_css('h1', text: BulkActions::REINDEX.label)
    expect(page).to have_css('p', text: BulkActions::REINDEX.help_text)
    expect(page).to have_field('Describe this bulk action', type: 'textarea')

    expect(page).to have_button('Submit', type: 'submit')
    expect(page).to have_link('Cancel', href: '/bulk_actions/new')
  end
end
