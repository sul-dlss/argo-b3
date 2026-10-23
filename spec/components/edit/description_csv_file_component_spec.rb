# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::DescriptionCsvFileComponent, type: :component do
  let(:component) { described_class.new(form:, druid_token: 'abc123') }
  let(:form) { ActionView::Helpers::FormBuilder.new(:edit_item, EditItemForm.new, vc_test_view_context, {}) }

  it 'renders the file field with a link to download the description spreadsheet' do
    render_inline(component)

    expect(page).to have_field('edit_item[description_csv_file]', type: 'file')
    expect(page).to have_link('Download description spreadsheet', href: '/objects/abc123/descriptive_csv')
  end
end
