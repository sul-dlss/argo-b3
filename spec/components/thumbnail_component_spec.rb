# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThumbnailComponent, type: :component do
  let(:component) { described_class.new(result:) }
  let(:result) { SearchResults::Item.new(solr_doc:, index: 1) }
  let(:solr_doc) { build(:solr_item, title:, first_shelved_image:) }
  let(:title) { 'Test Title' }
  let(:first_shelved_image) { nil }

  context 'without a thumbnail_url' do
    it 'does not render a thumbnail' do
      expect(component.render?).to be false
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

  context 'with a thumbnail_url and a dimension' do
    let(:component) { described_class.new(result:, dimension: 300) }
    let(:first_shelved_image) { 'default.jpg' }

    it 'renders the thumbnail' do
      render_inline(component)
      expect(page).to have_css "img[src*='default/full/!300,300/0/default.jpg']"
      expect(page).to have_css "img[alt='']"
    end
  end
end
