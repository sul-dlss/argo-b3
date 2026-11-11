# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Layout::ContainerComponent, type: :component do
  it 'renders the content in a container with the given classes and attributes, without a heading' do
    render_inline(described_class.new(classes: 'b3-form', data: { controller: 'report' })) { 'My content' }

    expect(page).to have_css('div.container.b3-form[data-controller="report"]', text: 'My content')
    expect(page).to have_no_css('h1')
    expect(page).to have_no_css('p')
  end

  it 'renders the heading before the content' do
    render_inline(described_class.new(heading: 'My heading')) { '<span>My content</span>'.html_safe }

    expect(page).to have_css('div.container > h1:first-child', exact_text: 'My heading')
    expect(page).to have_css('h1 + span', text: 'My content')
    expect(page).to have_no_css('p')
  end

  it 'renders the subtitle between the heading and the content' do
    render_inline(described_class.new(heading: 'My heading', subtitle: 'My subtitle')) do
      '<span>My content</span>'.html_safe
    end

    expect(page).to have_css('h1 + p', exact_text: 'My subtitle')
    expect(page).to have_css('p + span', text: 'My content')
  end

  it 'renders the breadcrumb before the heading' do
    render_inline(described_class.new(heading: 'My heading')) do |component|
      component.with_breadcrumb { '<nav class="breadcrumb">Parent</nav>'.html_safe }
    end

    expect(page).to have_css('div.container > nav.breadcrumb:first-child + h1', exact_text: 'My heading')
  end
end
