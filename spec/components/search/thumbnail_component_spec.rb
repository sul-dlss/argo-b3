# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ThumbnailComponent, type: :component do
  let(:component) { described_class.new(result:) }
  let(:result) { SearchResults::Item.new(solr_doc:, index: 1) }

  context 'without a thumbnail_url and a long title' do
    let(:title) do
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin dolor mauris, ' \
        'tincidunt ut elementum sollicitudin, luctus sit amet quam. Interdum et ' \
        'malesuada fames ac ante ipsum primis in faucibus.  Proin maximus, urna id ' \
        'gravida sodales, dui ex ullamcorper ante, vestibulum consectetur odio arcu ' \
        'mattis dolor. '
    end
    let(:first_shelved_image) { nil }
    let(:solr_doc) { build(:solr_item, title:, first_shelved_image:) }

    it 'truncates the citation' do
      render_inline(component)
      expect(page).to have_css "svg[aria-label='Placeholder: Responsive image']",
                               text: 'John Doe Lorem ipsum dolor sit amet, consectetur adipiscing elit'
    end
  end

  context 'with a thumbnail_url' do
    let(:solr_doc) { build(:solr_item) }

    it 'renders the thumbnail' do
      render_inline(component)
      expect(page).to have_css "img[src*='default/full/!400,400/0/default.jpg']"
      expect(page).to have_css "img[alt='']"
    end
  end
end
