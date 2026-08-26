# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::TagComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:component) { described_class.new(tags:, pinned_tags:) }

  let(:tags) { ['Registered By : ABC'] }
  let(:pinned_tags) { Set.new }

  it 'renders a link and pin button for each tag' do
    render_inline(component)

    expect(page).to have_css('h2', text: 'Tags')
    tags.each do |tag|
      expect(page).to have_link(tag, href: search_path(tags: [tag]))
    end
  end

  context 'when there are no tags' do
    let(:tags) { [] }

    it 'renders the heading and no list items' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Tags')
      expect(page).to have_no_css('li')
    end
  end

  context 'when a tag is a ticket tag' do
    let(:tags) { ['Ticket : DIGREQ-123'] }

    it 'links to the tickets facet search, with the prefix stripped' do
      render_inline(component)

      expect(page).to have_link('Ticket : DIGREQ-123', href: search_path(tickets: ['DIGREQ-123']))
    end
  end

  context 'when a tag is a project tag' do
    let(:tags) { ['Project : XYZ'] }
    let(:pinned_tags) { Set['Project : XYZ'] }

    it 'links to the projects facet search, with the prefix stripped' do
      render_inline(component)

      expect(page).to have_link('Project : XYZ', href: search_path(projects: ['XYZ']))
    end
  end
end
