# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ThumbnailComponent, type: :component do
  let(:component) { described_class.new(result:) }
  let(:result) { SearchResults::Item.new(solr_doc:, index: 1) }
  let(:solr_doc) { build(:solr_item, title:, first_shelved_image:) }
  let(:title) { 'Test Title' }
  let(:first_shelved_image) { nil }

  context 'without a thumbnail_url and a short title' do
    it 'does not truncate the citation in the placeholder' do
      render_inline(component)
      expect(page).to have_css "svg[aria-label='Placeholder: Responsive image']",
                               text: 'John Doe Test Title'
    end
  end

  context 'without a thumbnail_url and a long title' do
    let(:title) do
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin dolor mauris, ' \
        'tincidunt ut elementum sollicitudin, luctus sit amet quam. Interdum et ' \
        'malesuada fames ac ante ipsum primis in faucibus.  Proin maximus, urna id ' \
        'gravida sodales, dui ex ullamcorper ante, vestibulum consectetur odio arcu ' \
        'mattis dolor. '
    end

    it 'truncates the citation in the placeholder' do
      render_inline(component)
      expect(page).to have_css "svg[aria-label='Placeholder: Responsive image']",
                               text: 'John Doe Lorem ipsum dolor sit amet, consectetur adipiscing elit'
    end
  end

  context 'with a thumbnail_url' do
    let(:first_shelved_image) { 'default.jpg' }

    it 'renders the thumbnail' do
      render_inline(component)
      expect(page).to have_css "img[src*='default/full/!400,400/0/default.jpg']"
      expect(page).to have_css "img[alt='']"
    end
  end
end
