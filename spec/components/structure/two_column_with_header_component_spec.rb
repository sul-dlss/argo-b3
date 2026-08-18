# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Structure::TwoColumnWithHeaderComponent, type: :component do
  it 'renders the top, left, and main content in their respective regions' do
    render_inline(described_class.new) do |component|
      component.with_top_content { '<p class="top">Top content</p>'.html_safe }
      component.with_left_content { '<p class="left">Left content</p>'.html_safe }
      component.with_main_content { '<p class="main">Main content</p>'.html_safe }
    end

    expect(page).to have_css('p.top', text: 'Top content')
    expect(page).to have_css('.left-nav p.left', text: 'Left content')
    expect(page).to have_css('.row p.main', text: 'Main content')
    expect(page).to have_no_css('.row p.top')
  end
end
