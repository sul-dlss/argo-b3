# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::TicketTagComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new('item[ticket_tags_attributes][0]', tag_form, vc_test_view_context, {}) }
  let(:tag_form) { TicketTagForm.new(tag: 'ARGO-123') }

  it 'renders a field for the tag that suggests ticket tags' do
    render_inline(component)

    expect(page).to have_field('item[ticket_tags_attributes][0][tag]', with: 'ARGO-123')
    expect(page).to have_css('label.visually-hidden', text: 'Ticket')
    expect(page).to have_css('input[name="item[ticket_tags_attributes][0][tag]"]' \
                             '[data-controller="tag-select"]' \
                             '[data-tag-select-url-path-value="/tag_suggestions?type=ticket"]' \
                             '[data-action="input->tag-select#sync"]')
  end
end
