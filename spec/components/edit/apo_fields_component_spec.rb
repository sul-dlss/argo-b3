# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ApoFieldsComponent, type: :component do
  let(:component) { described_class.new(form:, agreement_options: [['My Agreement', 'druid:bc123df4567']]) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:apo, apo_form, vc_test_view_context, {}) }
  let(:apo_form) do
    ApoForm.new(title: 'My APO', agreement_druid: 'druid:bc123df4567', access_view: 'world', access_download: 'world',
                use_and_reproduction_statement: 'Use at will.', copyright: 'Copyright © Stanford.',
                license: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode')
  end

  it 'renders the required title and agreement fields' do
    render_inline(component)

    expect(page).to have_field('Title', with: 'My APO')
    expect(page).to have_css('label', text: 'Title') { |label| label.has_css?('span.required', text: '*') }
    expect(page).to have_select('Agreement', options: ['My Agreement'], selected: 'My Agreement')
    expect(page).to have_css('label', text: 'Agreement') { |label| label.has_css?('span.required', text: '*') }
  end

  it 'renders the object defaults fieldset' do
    render_inline(component)

    expect(page).to have_css('fieldset legend label.h3', text: 'Object defaults')
    expect(page).to have_css('fieldset', text: 'The following defaults will apply to all newly registered objects.')
    expect(page).to have_select('View access', selected: 'World')
    expect(page).to have_select('Download access', selected: 'World')
    expect(page).to have_field('Default use and reproduction', type: 'textarea', with: 'Use at will.')
    expect(page).to have_field('Default copyright', type: 'textarea', with: 'Copyright © Stanford.')
    expect(page).to have_select('Default license', selected: 'CC Zero 1.0')
  end
end
