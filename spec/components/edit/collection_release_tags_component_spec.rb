# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::CollectionReleaseTagsComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:release_tags, CollectionReleaseTagsForm.new, vc_test_view_context, {}) }

  it 'renders a row for each target' do
    render_inline(component)

    expect(page).to have_field('Release to SearchWorks')
    expect(page).to have_field('Release to EarthWorks')
    expect(page).to have_field('Release to Search engines')
  end
end
