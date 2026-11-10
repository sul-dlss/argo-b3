# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Layout::TabListComponent, type: :component do
  it 'renders the tabs and panes in columns matching the two column layout' do
    render_inline(described_class.new(id: 'tabbed_form', active_tab_name: :tab_one)) do |component|
      component.with_tab(label: 'Tab 1', tab_name: :tab_one)
      component.with_pane('<p class="pane">Pane content</p>'.html_safe)
    end

    expect(page).to have_css('.tab-form > .col-xl-2.col-md-3 .nav-link', text: 'Tab 1')
    expect(page).to have_css('.tab-form > .col-xl-10.col-md-9 p.pane', text: 'Pane content')
  end
end
