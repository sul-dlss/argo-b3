# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::Forms::MountPathFieldComponent, type: :component do
  let(:mount_form) { MountForm.new(path: '/maps/project') }
  let(:form) { ActionView::Helpers::FormBuilder.new(:mount_form, mount_form, vc_test_view_context, {}) }

  before do
    allow(Settings).to receive(:mount_locations).and_return(['/maps', '/dor/staging/'])
  end

  it 'renders a labeled text field that suggests the mount locations' do
    render_inline(described_class.new(form:, field_name: :path, label_text: 'Mount path'))

    expect(page).to have_field('Mount path', type: 'text', with: '/maps/project')
    expect(page).to have_css('input#mount_form_path[list="mount_form_path_mount_locations"]')
    expect(page).to have_css('datalist#mount_form_path_mount_locations option[value="/maps/"]', visible: :all)
    expect(page).to have_css('datalist#mount_form_path_mount_locations option[value="/dor/staging/"]', visible: :all)
  end

  context 'with container classes' do
    it 'renders the container with the classes' do
      render_inline(described_class.new(form:, field_name: :path, label_text: 'Mount path',
                                        container_classes: 'my-field'))

      expect(page).to have_css('div.my-field > input#mount_form_path')
    end
  end
end
