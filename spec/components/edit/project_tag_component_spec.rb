# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ProjectTagComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new('item[project_tags_attributes][0]', tag_form, vc_test_view_context, {}) }
  let(:tag_form) { ProjectTagForm.new(tag: 'Argo : Phase 1') }

  it 'renders a field for the tag' do
    render_inline(component)

    expect(page).to have_field('item[project_tags_attributes][0][tag]', with: 'Argo : Phase 1')
    expect(page).to have_css('label.visually-hidden', text: 'Project name')
    expect(page).to have_no_css('[data-controller="tag-select"]')
  end

  context 'when suggesting tags' do
    let(:component) { described_class.new(form:, suggest: true) }

    it 'wires the field to suggest project tags' do
      render_inline(component)

      expect(page).to have_css('input[name="item[project_tags_attributes][0][tag]"]' \
                               '[data-controller="tag-select"]' \
                               '[data-tag-select-url-path-value="/tag_suggestions?type=project"]' \
                               '[data-action="input->tag-select#sync"]')
    end
  end
end
