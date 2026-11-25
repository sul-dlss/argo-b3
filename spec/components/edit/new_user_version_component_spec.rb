# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::NewUserVersionComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, edit_item_form, vc_test_view_context, {}) }
  let(:edit_item_form) do
    EditItemForm.build_from_cocina_object(cocina_object).tap do |item_form|
      item_form.version_service = version_service_double(version: 2)
    end
  end
  let(:cocina_object) do
    build(:dro_with_metadata, version: 2).new(access: { view: 'world', download: 'world' })
  end
  let(:legend) { 'Do you want to keep the previous version accessible as a public version?' }

  it 'renders the question with No selected' do
    render_inline(component)

    expect(page).to have_css('fieldset:not([hidden]):not([disabled]) legend', text: legend)
    expect(page).to have_field('Yes', type: 'radio', checked: false)
    expect(page).to have_field('No', type: 'radio', checked: true)
    expect(page.all('input[type="radio"]').map(&:value)).to eq %w[true false]
  end

  context 'when the item is dark' do
    let(:cocina_object) { build(:dro_with_metadata, version: 2).new(access: { view: 'dark', download: 'none' }) }

    it 'renders the question hidden and disabled' do
      render_inline(component)

      expect(page).to have_css('fieldset[hidden][disabled] legend', text: legend, visible: :hidden)
    end
  end

  context 'when the feature is off' do
    before { allow(Settings.feature_flags).to receive(:new_user_version).and_return(false) }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_css('fieldset', visible: :all)
    end
  end

  context 'when depositing the first version' do
    let(:edit_item_form) do
      EditItemForm.build_from_cocina_object(cocina_object).tap do |item_form|
        item_form.version_service = version_service_double(version: 1)
      end
    end

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_css('fieldset', visible: :all)
    end
  end
end
