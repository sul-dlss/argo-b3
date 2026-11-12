# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::BoxRowComponent, type: :component do
  it 'renders the boxes in order within the row, with the given attributes' do
    render_inline(described_class.new(id: 'box-row', role: 'status')) do
      '<div class="show-box">First</div><div class="show-box">Second</div>'.html_safe
    end

    expect(page).to have_css('div#box-row[role="status"] > .show-box:first-child', text: 'First')
    expect(page).to have_css('div#box-row[role="status"] > .show-box:last-child', text: 'Second')
  end
end
