# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::CollectionReleaseTargetComponent, type: :component do
  let(:form) { ActionView::Helpers::FormBuilder.new(:release_tags, release_tags_form, vc_test_view_context, {}) }
  let(:release_tags_form) do
    CollectionReleaseTagsForm.new(searchworks_release: true, searchworks_what: 'collection',
                                  earthworks_release: true, earthworks_what: 'self')
  end

  context 'when the target releases the collection and its member items' do
    it 'checks the target and the collection and member items choice' do
      render_inline(described_class.new(form:, prefix: :searchworks))

      expect(page).to have_checked_field('Release to SearchWorks')
      choices = page.find(:fieldset, 'Include in release to SearchWorks')
      expect(choices).to have_checked_field('Collection and member items')
      expect(choices).to have_unchecked_field('Collection', exact: true)
    end
  end

  context 'when the target releases the collection alone' do
    it 'checks the target and the collection choice' do
      render_inline(described_class.new(form:, prefix: :earthworks))

      expect(page).to have_checked_field('Release to EarthWorks')
      expect(page).to have_no_text('requires geo coordinates')
      expect(page.find(:fieldset, 'Include in release to EarthWorks')).to have_checked_field('Collection', exact: true)
    end
  end

  context 'when the target is not released' do
    it 'leaves the target unchecked and its choices disabled and unchecked' do
      render_inline(described_class.new(form:, prefix: :purl_sitemap))

      expect(page).to have_unchecked_field('Release to Search engines')
      choices = page.find(:fieldset, 'Include in release to Search engines')
      expect(choices).to have_field('Collection', exact: true, disabled: true, checked: false)
      expect(choices).to have_field('Collection and member items', disabled: true, checked: false)
    end
  end
end
