# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::FileAdministrativeComponent, type: :component do
  let(:component) { described_class.new(form:, container_classes: 'my-fieldset') }
  let(:form) { ActionView::Helpers::FormBuilder.new(:content_file, content_file_form, vc_test_view_context, {}) }
  let(:content_file_form) { ContentFileForm.new(administrative: ContentFileForm::PUBLISH_ONLY) }

  it 'renders the administrative radio buttons' do
    render_inline(component)

    expect(page).to have_css('fieldset.my-fieldset legend', text: 'Administrative')
    expect(page).to have_field('Publish and preserve', type: 'radio', checked: false)
    expect(page).to have_field('Publish only', type: 'radio', checked: true)
    expect(page).to have_field('Preserve only', type: 'radio', checked: false)
  end

  context 'when the administrative option is invalid' do
    before { content_file_form.validate }

    let(:content_file_form) { ContentFileForm.new(administrative: nil) }

    it 'renders the error' do
      render_inline(component)

      expect(page).to have_css('.invalid-feedback', text: 'must be selected')
    end
  end
end
