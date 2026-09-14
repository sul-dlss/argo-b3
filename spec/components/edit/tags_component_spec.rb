# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::TagsComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new('item', item_form, vc_test_view_context, {}) }
  let(:item_form) { ItemForm.new(other_tags_attributes: [{ tag: 'Registered By : mjgiarlo' }]) }

  it 'renders a fieldset for each type of tag' do
    render_inline(component)

    expect(page).to have_css('fieldset legend', text: 'Tags')
    expect(page).to have_css('fieldset legend', text: 'Project names')
    expect(page).to have_css('fieldset legend', text: 'Tickets')
  end

  it 'renders the fields for the tags' do
    render_inline(component)

    expect(page).to have_field('item[other_tags_attributes][0][tag]', with: 'Registered By : mjgiarlo')
    expect(page).to have_field('item[project_tags_attributes][0][tag]')
    expect(page).to have_field('item[ticket_tags_attributes][0][tag]')
  end

  it 'renders a button for adding each type of tag' do
    render_inline(component)

    expect(page).to have_button('Add another tag')
    expect(page).to have_button('Add another project')
    expect(page).to have_button('Add another ticket')
  end
end
