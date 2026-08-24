# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::EmbargoBannerComponent, type: :component do
  subject(:component) { described_class.new(release_date:, edit_path:) }

  let(:release_date) { '2029-01-01 12:00:00 AM' }
  let(:edit_path) { '/objects/druid:bc123df4567/embargo/edit' }

  it 'renders a full-width black banner with the release date and edit link' do
    render_inline(component)

    expect(page).to have_css('.embargo-banner.bg-black.text-white h2', text: 'Embargoed until 2029-01-01')
    expect(page).to have_css("a[aria-label='Edit embargo release date'][href='#{edit_path}']")
    expect(page).to have_css('a i.bi-pencil')
  end

  context 'without an embargo release date' do
    let(:release_date) { nil }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_css('.embargo-banner')
    end
  end

  context 'without an edit path' do
    let(:edit_path) { nil }

    it 'renders the pencil icon without an edit link' do
      render_inline(component)

      expect(page).to have_css('.embargo-banner', text: 'Embargoed until 2029-01-01')
      expect(page).to have_css('.embargo-banner h2 > i.bi-pencil')
      expect(page).to have_no_css("a[aria-label='Edit embargo release date']")
    end
  end
end
