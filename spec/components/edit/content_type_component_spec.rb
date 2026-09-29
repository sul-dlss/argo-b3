# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ContentTypeComponent, type: :component do
  let(:component) { described_class.new(form:, container_classes: 'mb-3') }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, item_form, vc_test_view_context, {}) }
  let(:item_form) { ItemForm.new(content_type: Cocina::Models::ObjectType.image) }

  it 'renders the content type select' do
    render_inline(component)

    expect(page).to have_select('Content type', selected: 'image', options: Constants::REGISTRATION_CONTENT_TYPES.keys)
  end

  context 'with input data' do
    let(:component) { described_class.new(form:, input_data: { action: 'change->my-controller#toggle' }) }

    it 'adds the data to the select' do
      render_inline(component)

      expect(page).to have_css('select[data-action="change->my-controller#toggle"]')
    end
  end

  context 'when the content type is not a registration content type' do
    let(:item_form) { ItemForm.new(content_type: Cocina::Models::ObjectType.manuscript) }

    it 'adds the content type to the options' do
      render_inline(component)

      expect(page).to have_select('Content type', selected: 'manuscript',
                                                  options: Constants::REGISTRATION_CONTENT_TYPES.keys + ['manuscript'])
    end
  end

  it 'applies the container classes' do
    render_inline(component)

    expect(page).to have_css('.mb-3', text: 'Content type')
  end
end
