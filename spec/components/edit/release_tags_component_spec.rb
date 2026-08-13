# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ReleaseTagsComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(nil, release_tags_form, vc_test_view_context, {}) }

  context 'when no release choice has been made' do
    let(:release_tags_form) { ReleaseTagsForm.new }

    it 'renders the default state' do
      render_inline(component)

      expect(page).to have_field('Use collection level settings', type: 'radio', disabled: true)

      expect(page).to have_field('Release to:', type: 'radio', checked: false)
      expect(page).to have_field('SearchWorks', type: 'checkbox', checked: false)
      expect(page).to have_field('EarthWorks', type: 'checkbox', checked: false)
      expect(page).to have_field('Search engines', type: 'checkbox', checked: false)

      expect(page).to have_field('Do not release.', type: 'radio', checked: true)
    end
  end

  context 'when release to targets has been chosen' do
    let(:release_tags_form) do
      ReleaseTagsForm.new(release_choice: ReleaseTagsForm::RELEASE_TO_TARGETS, searchworks_target: true)
    end

    it 'renders the release to targets state' do
      render_inline(component)

      expect(page).to have_field('Release to:', type: 'radio', checked: true)
      expect(page).to have_field('SearchWorks', type: 'checkbox', checked: true)
      expect(page).to have_field('EarthWorks', type: 'checkbox', checked: false)
      expect(page).to have_field('Search engines', type: 'checkbox', checked: false)

      expect(page).to have_field('Do not release.', type: 'radio', checked: false)
    end
  end

  context 'when no target has been selected' do
    let(:release_tags_form) do
      ReleaseTagsForm.new(release_choice: ReleaseTagsForm::RELEASE_TO_TARGETS).tap(&:valid?)
    end

    it 'renders the validation error' do
      render_inline(component)

      expect(page).to have_text('At least one target must be selected')
    end
  end
end
