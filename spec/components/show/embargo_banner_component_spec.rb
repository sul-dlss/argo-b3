# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::EmbargoBannerComponent, type: :component do
  subject(:component) { described_class.new(release_date:) }

  let(:release_date) { '2029-01-01 12:00:00 AM' }

  it 'renders a full-width black banner with the release date and pencil icon' do
    render_inline(component)

    expect(page).to have_css('.embargo-banner.bg-black.text-white h2', text: 'Embargoed until 2029-01-01')
    expect(page).to have_css('.embargo-banner h2 > i.bi-pencil')
    expect(page).to have_no_link
  end

  context 'without an embargo release date' do
    let(:release_date) { nil }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_css('.embargo-banner')
    end
  end
end
