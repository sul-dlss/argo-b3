# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::UseAndReproductionStatementComponent, type: :component do
  let(:component) { described_class.new(form:, container_classes: 'my-fieldset') }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, item_form, vc_test_view_context, {}) }
  let(:item_form) { ItemForm.new(use_and_reproduction_statement: 'Property rights reside with the repository.') }

  it 'renders the use and reproduction statement text area' do
    render_inline(component)

    expect(page).to have_field('Use and reproduction', type: 'textarea',
                                                       with: 'Property rights reside with the repository.')
  end

  it 'applies the container classes' do
    render_inline(component)

    expect(page).to have_css('.my-fieldset', text: 'Use and reproduction')
  end
end
