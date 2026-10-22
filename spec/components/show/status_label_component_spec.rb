# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::StatusLabelComponent, type: :component do
  it 'renders the deposited label with a success icon' do
    render_inline(described_class.new(status: :deposited))

    expect(page).to have_text('Deposited')
    expect(page).to have_css('i.bi-check-circle-fill.text-success')
  end

  it 'renders the error label with a danger icon' do
    render_inline(described_class.new(status: :error))

    expect(page).to have_text('Error')
    expect(page).to have_css('i.bi-exclamation-triangle-fill.text-danger')
  end

  it 'renders the staging failed label with a danger icon' do
    render_inline(described_class.new(status: :staging_failed))

    expect(page).to have_text('Staging failed')
    expect(page).to have_css('i.bi-exclamation-triangle-fill.text-danger')
  end

  it 'renders the draft label without an icon' do
    render_inline(described_class.new(status: :draft))

    expect(page).to have_text('Draft, not deposited')
    expect(page).to have_no_css('i')
  end
end
