# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::AccessAndEmbargoComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, item_form, vc_test_view_context, {}) }
  let(:item_form) { ItemForm.new }

  it 'renders the embargo toggle' do
    render_inline(component)

    expect(page).to have_field('Without embargo', type: 'radio')
    expect(page).to have_field('With embargo', type: 'radio')
  end

  it 'renders the embargo release date field' do
    render_inline(component)

    expect(page).to have_field('When will this embargo end?', type: 'date', name: 'item[embargo_release_date]')
  end

  it 'renders the access rights for each embargo state' do
    render_inline(component)

    expect(page).to have_select('View access', name: 'item[access_view]', count: 2)
    expect(page).to have_select('View access', name: 'item[embargo_view]', count: 1)
  end

  it 'renders the fieldset labels' do
    render_inline(component)

    expect(page).to have_css('legend', text: 'Access settings during embargo')
    expect(page).to have_css('legend', text: 'Access settings once embargo ends')
  end

  it 'renders the targets that the toggle Stimulus controller expects' do
    render_inline(component)

    expect(page).to have_css('[data-controller="toggle"]')
    expect(page).to have_css('input[data-toggle-target="radio"][data-toggle-section="without-embargo"]')
    expect(page).to have_css('input[data-toggle-target="radio"][data-toggle-section="with-embargo"]')
    expect(page).to have_css('[data-toggle-target="section"][data-toggle-section="without-embargo"]')
    expect(page).to have_css('[data-toggle-target="section"][data-toggle-section="with-embargo"]')
  end
end
