# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Search' do
  before do
    sign_in(create(:user, :reader))
  end

  context 'when results and facets are loading' do
    it 'renders a heading outline without skipped levels' do
      get search_path, params: { query: 'test' }

      # Starts at the h1, skipping the site header.
      outline = heading_outline(response.body).drop_while { |level, _| level != 1 }
      expect(outline.first(8)).to eq [
        [1, 'Search results'],
        [2, 'Your selections'],
        [2, 'Project results (Loading ...)'],
        [3, '1.'], [3, '2.'], [3, '3.'], [3, '4.'], [3, '5.']
      ]
      expect(outline).to include([2, 'Tag results (Loading ...)'], [2, 'Ticket results (Loading ...)'],
                                 [2, 'Item, collection, and APO results (Loading ...)'])
      expect(outline.drop_while { |_, text| text != 'Limit your search' }.first(2))
        .to eq [[2, 'Limit your search'], [3, 'Project Loading Project ...']]
      expect(outline.each_cons(2)).to all(satisfy { |(previous, _), (current, _)| current - previous <= 1 })
    end
  end
end
