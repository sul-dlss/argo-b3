# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::CopyrightComponent, type: :component do
  let(:component) { described_class.new(form:, container_classes: 'my-fieldset') }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, item_form, vc_test_view_context, {}) }
  let(:item_form) { ItemForm.new(copyright: 'Copyright © Stanford University.') }

  it 'renders the copyright text area' do
    render_inline(component)

    expect(page).to have_field('Copyright', type: 'textarea', with: 'Copyright © Stanford University.')
  end

  it 'applies the container classes' do
    render_inline(component)

    expect(page).to have_css('.my-fieldset', text: 'Copyright')
  end
end
