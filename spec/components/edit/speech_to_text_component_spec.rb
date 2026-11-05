# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::SpeechToTextComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:contents_item, contents_item_form, vc_test_view_context, {}) }
  let(:contents_item_form) do
    ContentsItemForm.build_from_cocina_object(build(:dro_with_metadata, type: Cocina::Models::ObjectType.media))
  end

  it 'renders the speech to text radios with No selected' do
    render_inline(component)

    expect(page).to have_css('legend', text: 'Do you want to auto-generate captions or transcripts for the media?')
    expect(page).to have_field('Yes', type: 'radio', checked: false)
    expect(page).to have_field('No', type: 'radio', checked: true)
    expect(page.all('input[type="radio"][name="contents_item[perform_speech_to_text]"]').map(&:value))
      .to eq(%w[false true])
  end

  context 'when speech to text has been requested' do
    let(:contents_item_form) { super().tap { |form| form.perform_speech_to_text = true } }

    it 'selects Yes' do
      render_inline(component)

      expect(page).to have_field('Yes', type: 'radio', checked: true)
    end
  end

  context 'with data attributes' do
    let(:component) { described_class.new(form:, data: { content_type_dependent_target: 'dependent' }) }

    it 'adds them to the fieldset' do
      render_inline(component)

      expect(page).to have_css('fieldset[data-content-type-dependent-target="dependent"]')
    end
  end
end
