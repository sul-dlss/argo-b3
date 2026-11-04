# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ReleaseTagsComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(nil, release_tags_form, vc_test_view_context, {}) }

  context 'when different release choices have been made' do
    let(:release_tags_form) do
      ReleaseTagsForm.new(searchworks_target: 'release_to_targets', earthworks_target: 'no_release',
                          purl_sitemap_target: 'release_to_collection')
    end

    it 'renders three independently selected dropdowns with the release choices' do
      render_inline(component)

      expect(page).to have_select('SearchWorks', selected: 'Release',
                                                 options: ['Follow collection settings', 'Release', 'Do not release'])
      expect(page).to have_select('EarthWorks', selected: 'Do not release',
                                                options: ['Follow collection settings', 'Release', 'Do not release'])
      expect(page).to have_select('Search engines',
                                  selected: 'Follow collection settings',
                                  options: ['Follow collection settings', 'Release', 'Do not release'])
      expect(page).to have_text('EarthWorks (requires geo coordinates or release will not be successful)')
      expect(page).to have_no_css('input[type="radio"], input[type="checkbox"]')
    end
  end

  context 'when follow collection is disabled for a target' do
    let(:component) { described_class.new(form:, follow_collection_disabled_fields: [:searchworks_target]) }
    let(:release_tags_form) { ReleaseTagsForm.new(searchworks_target: 'no_release') }

    it 'disables the follow collection choice for only that target' do
      render_inline(component)

      expect(page).to have_select('SearchWorks', selected: 'Do not release',
                                                 disabled_options: ['Follow collection settings'])
      expect(page).to have_select('Search engines', disabled_options: [])
    end
  end

  context 'with options for a collection' do
    let(:component) do
      described_class.new(form:, options: [['Do not release', 'no_release'], ['Release collection', 'self']])
    end
    let(:release_tags_form) { CollectionReleaseTagsForm.new(searchworks_target: 'self') }

    it 'renders the dropdowns with the given options' do
      render_inline(component)

      expect(page).to have_select('SearchWorks', selected: 'Release collection',
                                                 options: ['Do not release', 'Release collection'])
      expect(page).to have_select('EarthWorks (requires geo coordinates or release will not be successful)',
                                  selected: 'Do not release', options: ['Do not release', 'Release collection'])
      expect(page).to have_select('Search engines', selected: 'Do not release',
                                                    options: ['Do not release', 'Release collection'])
    end
  end
end
