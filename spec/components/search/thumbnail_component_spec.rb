# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ThumbnailComponent, type: :component do
  let(:component) { described_class.new(result:) }
  let(:rendered) { render_inline(component) }
  let(:result) do
    double(SearchResults::Item, # rubocop:disable RSpec/VerifiedDoubles
           title:,
           druid: 'druid:ab123cd4567',
           bare_druid: 'ab123cd4567',
           author:,
           publisher:,
           publication_place:,
           publication_date:,
           first_shelved_image:)
  end
  let(:title) { 'The Great Book' }
  let(:author) { 'John Doe' }
  let(:publisher) { ['Famous Publisher'] }
  let(:publication_place) { ['New York'] }
  let(:publication_date) { '2020' }
  let(:italicize) { false }
  let(:first_shelved_image) { nil }

  context 'without a thumbnail_url and a long title' do
    let(:title) do
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin dolor mauris, ' \
        'tincidunt ut elementum sollicitudin, luctus sit amet quam. Interdum et ' \
        'malesuada fames ac ante ipsum primis in faucibus.  Proin maximus, urna id ' \
        'gravida sodales, dui ex ullamcorper ante, vestibulum consectetur odio arcu ' \
        'mattis dolor. '
    end

    it 'truncates the citation' do
      render_inline(component)
      expect(page).to have_text 'John Doe Lorem ipsum dolor sit amet, consectetur adipiscing elit'
    end
  end

  context 'with a thumbnail_url' do
    let(:first_shelved_image) { 'something.jpg' }

    context 'with object_type == image' do
      it 'renders the thumbnail' do
        render_inline(component)
        expect(page).to have_css "img[src*='something/full/!400,400/0/default.jpg']"
        expect(page).to have_css "img[alt='John Doe The Great Book: Famous Publisher, New York, 2020']"
      end
    end
  end
end
