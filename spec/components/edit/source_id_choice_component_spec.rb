# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::SourceIdChoiceComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(nil, item_form, vc_test_view_context, {}) }

  context 'when source id is provided' do
    let(:item_form) { ItemForm.new(source_id: 'sul:1234') }

    it 'renders the provided state' do
      render_inline(component)

      expect(page).to have_field('Enter source ID', type: 'radio', checked: true)
      expect(page).to have_field('Source ID', type: 'text', with: 'sul:1234')

      expect(page).to have_field('Enter prefix to autogenerate source ID', type: 'radio', checked: false)
    end
  end

  context 'when source id is generated' do
    let(:item_form) do
      ItemForm.new(source_id_choice: ItemForm::SOURCE_ID_GENERATE_CHOICE, source_id_prefix: 'sul')
    end

    it 'renders the generate state' do
      render_inline(component)

      expect(page).to have_field('Enter source ID', type: 'radio', checked: false)

      expect(page).to have_field('Enter prefix to autogenerate source ID', type: 'radio', checked: true)
      expect(page).to have_field('Source ID prefix', type: 'text', with: 'sul')
    end
  end
end
