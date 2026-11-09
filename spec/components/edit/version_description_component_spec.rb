# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::VersionDescriptionComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:agreement, edit_agreement_form, vc_test_view_context, {}) }
  let(:edit_agreement_form) do
    EditAgreementForm.build_from_cocina_object(build(:agreement_with_metadata)).tap do |agreement_form|
      agreement_form.version_description = 'Fixed the title'
    end
  end

  it 'renders the required version description field' do
    render_inline(component)

    expect(page).to have_field('Version description', with: 'Fixed the title')
    expect(page).to have_css('label', text: 'Version description') { |label| label.has_css?('span.required') }
  end

  context 'with label classes, container classes, and help text' do
    let(:component) do
      described_class.new(form:, label_classes: 'fw-bold', container_classes: 'my-field',
                          help_text: 'Applied to items without one.')
    end

    it 'renders them' do
      render_inline(component)

      expect(page).to have_css('.my-field label.fw-bold', text: 'Version description')
      expect(page).to have_text('Applied to items without one.')
    end
  end

  context 'when disabled' do
    let(:component) { described_class.new(form:, disabled: true) }

    it 'renders a disabled field that is not marked required' do
      render_inline(component)

      expect(page).to have_field('Version description', disabled: true)
      expect(page).to have_no_css('label span.required')
    end
  end
end
