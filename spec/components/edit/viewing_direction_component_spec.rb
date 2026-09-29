# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ViewingDirectionComponent, type: :component do
  let(:component) { described_class.new(form:, container_classes: 'mb-3') }
  let(:form) { ActionView::Helpers::FormBuilder.new(:manage_content_type, bulk_action_form, vc_test_view_context, {}) }
  let(:bulk_action_form) { BulkActions::ManageContentTypeForm.new(viewing_direction: 'right-to-left') }

  it 'renders the viewing direction select' do
    render_inline(component)

    expect(page).to have_select('Viewing direction', selected: 'right-to-left', options: Constants::VIEWING_DIRECTIONS)
  end

  it 'applies the container classes' do
    render_inline(component)

    expect(page).to have_css('.mb-3', text: 'Viewing direction')
  end
end
