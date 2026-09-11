# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::DeleteButtonComponent, type: :component do
  it 'renders an icon-only button with a visually hidden "Remove" label' do
    render_inline(described_class.new)

    expect(page).to have_css('button i.bi-trash')
    expect(page).to have_css('button .visually-hidden', text: 'Remove', visible: :all)
  end

  it 'passes through additional attributes, such as a Stimulus action' do
    render_inline(described_class.new(data: { action: 'has-many#remove' }))

    expect(page).to have_css('button[data-action="has-many#remove"]')
  end

  it 'allows the label to be overridden' do
    render_inline(described_class.new(label: 'Clear'))

    expect(page).to have_css('.visually-hidden', text: 'Clear', visible: :all)
  end
end
