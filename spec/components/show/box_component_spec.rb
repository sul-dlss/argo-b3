# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::BoxComponent, type: :component do
  let(:component) { described_class.new(heading: 'Tags') }

  it 'renders the heading and yielded content within the box' do
    render_inline(component) { '<li>Testing 1-2-3</li>'.html_safe }

    expect(page).to have_css('.card.object-type-border.object-type-bg-light h2.card-title', text: 'Tags')
    expect(page).to have_css('.card-body li', text: 'Testing 1-2-3')
  end

  it 'renders the heading action beside the heading' do
    render_inline(component) { |box| box.with_heading_action { '<a href="/edit">Edit</a>'.html_safe } }

    expect(page).to have_css('.d-flex h2.card-title + a[href="/edit"]', text: 'Edit')
  end

  context 'with a heading level and classes' do
    let(:component) { described_class.new(heading: '# of errors', heading_level: :h4, classes: 'text-danger') }

    it 'renders the heading at that level and adds the classes to the box' do
      render_inline(component) { '3' }

      expect(page).to have_css('.card.object-type-border.object-type-bg-light.text-danger h4.card-title',
                               text: '# of errors')
      expect(page).to have_no_css('h2')
    end
  end
end
