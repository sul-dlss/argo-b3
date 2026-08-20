# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ReleasedToComponent, type: :component do
  subject(:component) { described_class.new(object_released_presenter:) }

  let(:heading) { 'Released to' }
  let(:release_tag_links) do
    [
      { label: 'Searchworks', url: 'https://searchworks.stanford.edu/view/druid:bc123df4567' },
      { label: 'PURL sitemap', url: 'https://purl.stanford.edu/bc123df4567' }
    ]
  end
  let(:object_released_presenter) do
    instance_double(ObjectReleasedPresenter, heading:, release_tag_links:)
  end

  context 'when there are release target links' do
    it 'renders a link for each release target' do
      render_inline(component)

      expect(page).to have_link('Searchworks', href: 'https://searchworks.stanford.edu/view/druid:bc123df4567')
      expect(page).to have_link('PURL sitemap', href: 'https://purl.stanford.edu/bc123df4567')
    end
  end

  context 'when there are no release target links' do
    let(:heading) { 'Not released' }
    let(:release_tag_links) { [] }

    it 'renders the heading and no list' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Not released')
      expect(page).to have_no_css('ul')
    end
  end
end
