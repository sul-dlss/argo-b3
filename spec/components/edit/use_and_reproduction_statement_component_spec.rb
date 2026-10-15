# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::UseAndReproductionStatementComponent, type: :component do
  let(:component) { described_class.new(form:, container_classes: 'my-fieldset') }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, new_item_form, vc_test_view_context, {}) }
  let(:new_item_form) { NewItemForm.new(use_and_reproduction_statement: 'Property rights reside with the repository.') }

  it 'renders the use and reproduction statement text area' do
    render_inline(component)

    expect(page).to have_field('Use and reproduction', type: 'textarea',
                                                       with: 'Property rights reside with the repository.')
  end

  it 'applies the container classes' do
    render_inline(component)

    expect(page).to have_css('.my-fieldset', text: 'Use and reproduction')
  end

  it 'renders the help link, opening in a new tab' do
    render_inline(component)

    expect(page).to have_link('sample statements', href: Settings.links.use_and_reproduction_statement)
    expect(page).to have_css('a[target="_blank"][rel="noopener"]', text: 'sample statements')
  end

  context 'with a label' do
    let(:component) { described_class.new(form:, label_text: 'Default use and reproduction') }

    it 'renders the label' do
      render_inline(component)

      expect(page).to have_field('Default use and reproduction', type: 'textarea')
    end
  end

  context 'when showing APO defaults' do
    let(:component) { described_class.new(form:, apo_defaults: true) }

    it 'renders the targets that the apo-defaults Stimulus controller expects' do
      render_inline(component)

      expect(page).to have_css('textarea[name="item[use_and_reproduction_statement]"]' \
                               '[data-apo-defaults-target="useAndReproductionStatement"]')
      expect(page).to have_css('.form-text span[data-apo-defaults-target="useAndReproductionStatementText"]',
                               visible: :all)
    end
  end

  context 'when not showing APO defaults' do
    it 'does not render the apo-defaults targets' do
      render_inline(component)

      expect(page).to have_no_css('[data-apo-defaults-target]', visible: :all)
    end
  end
end
