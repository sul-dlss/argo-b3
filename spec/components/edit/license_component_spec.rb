# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::LicenseComponent, type: :component do
  let(:component) { described_class.new(form:, container_classes: 'my-fieldset') }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, item_form, vc_test_view_context, {}) }
  let(:item_form) { ItemForm.new(license: license_uri) }
  let(:license_uri) { Constants::LICENSE_OPTIONS.first[:uri] }

  it 'renders the license select with a blank option' do
    render_inline(component)

    expect(page).to have_select('License', selected: Constants::LICENSE_OPTIONS.first[:label],
                                           options: [''] + Constants::LICENSE_OPTIONS.pluck(:label))
  end

  it 'renders the help link, opening in a new tab' do
    render_inline(component)

    expect(page).to have_link('Get help selecting a license', href: Settings.links.license)
    expect(page).to have_css('a[target="_blank"][rel="noopener"]', text: 'Get help selecting a license')
  end

  it 'renders the help text' do
    render_inline(component)

    expect(page).to have_text('Assigning a license may improve discovery of your work in web searches.')
  end

  it 'applies the container classes' do
    render_inline(component)

    expect(page).to have_css('.my-fieldset', text: 'License')
  end

  context 'with a label' do
    let(:component) { described_class.new(form:, label_text: 'Default license') }

    it 'renders the label' do
      render_inline(component)

      expect(page).to have_select('Default license')
    end
  end

  context 'when hiding the help text' do
    let(:component) { described_class.new(form:, hide_help_text: true) }

    it 'does not render the help text' do
      render_inline(component)

      expect(page).to have_no_text('Assigning a license may improve discovery of your work in web searches.')
    end
  end
end
