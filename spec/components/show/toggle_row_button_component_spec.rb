# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ToggleRowButtonComponent, type: :component do
  it 'renders a collapsed button that toggles the details row' do
    render_inline(described_class.new(details_row_id: 'file-1-details',
                                      label: 'Show technical metadata for image1.tif'))

    expect(page).to have_css(
      "button.toggle-row-button.collapsed[type='button'][data-bs-toggle='collapse'][data-bs-target='#file-1-details']" \
      "[data-toggle-row-target='button'][aria-expanded='false'][aria-controls='file-1-details'] " \
      'i.bi-chevron-down'
    )
    expect(page).to have_button('Show technical metadata for image1.tif')
    expect(page).to have_css('button span.visually-hidden', text: 'Show technical metadata for image1.tif')
  end
end
