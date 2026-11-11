# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::FormComponent, type: :component do
  let(:component) { described_class.new(form:, bulk_action_config: BulkActions::REINDEX) }

  let(:form) { ActionView::Helpers::FormBuilder.new(nil, BulkActions::BasicForm.new, vc_test_view_context, {}) }

  it 'renders the bulk action form' do
    render_inline(component)

    expect(page).to have_css('h1', text: BulkActions::REINDEX.label)
    expect(page).to have_field('Describe this bulk action', type: 'textarea')

    expect(page).to have_button('Submit', type: 'submit')
    expect(page).to have_link('Cancel', href: '/bulk_actions/new')
  end

  it 'sets the page title' do
    # render_inline discards its view context afterwards, so hold on to it.
    view_context = vc_test_view_context
    render_inline(component)

    expect(view_context.content_for(:title)).to eq('Reindex')
  end
end
