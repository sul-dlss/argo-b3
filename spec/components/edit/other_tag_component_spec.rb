# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::OtherTagComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new('item[other_tags_attributes][0]', tag_form, vc_test_view_context, {}) }
  let(:tag_form) { OtherTagForm.new(tag: 'Registered By : mjgiarlo') }

  it 'renders a field for the tag that suggests other tags' do
    render_inline(component)

    expect(page).to have_field('item[other_tags_attributes][0][tag]', with: 'Registered By : mjgiarlo')
    expect(page).to have_css('label.visually-hidden', text: 'Tag')
    expect(page).to have_css('input[name="item[other_tags_attributes][0][tag]"]' \
                             '[data-controller="tag-select"]' \
                             '[data-tag-select-url-path-value="/tag_suggestions?type=other"]' \
                             '[data-action="input->tag-select#sync"]')
  end
end
