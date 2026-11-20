# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::DepositDropdownComponent, type: :component do
  subject(:component) { described_class.new(deposit_form:, druid:, disabled:) }

  let(:deposit_form) { DepositDraftForm.new(version_description: 'Fixed the title') }
  let(:druid) { 'druid:bc123df4567' }
  let(:disabled) { false }

  it 'renders a Deposit toggle for a form that deposits with the version description' do
    render_inline(component)

    expect(page).to have_button('Deposit', class: 'dropdown-toggle', disabled: false)
    expect(page).to have_css('button.dropdown-toggle[data-bs-toggle="dropdown"]', text: 'Deposit')
    form = page.find(".dropdown-menu form[action='/objects/#{druid}/deposit'][method='post']")
    expect(form).to have_field('Version description', with: 'Fixed the title')
    expect(form).to have_css('input[name="deposit[version_description]"][required]')
    expect(form).to have_button('Cancel', type: 'button')
    expect(form).to have_button('Deposit', type: 'submit')
  end

  it 'renders Cancel before Deposit' do
    render_inline(component)

    expect(page.all('.dropdown-menu button').map { it.text.strip }).to eq(%w[Cancel Deposit])
  end

  context 'when disabled' do
    let(:disabled) { true }

    it 'renders a disabled Deposit toggle' do
      render_inline(component)

      expect(page).to have_button('Deposit', class: %w[dropdown-toggle disabled], disabled: true)
    end
  end
end
