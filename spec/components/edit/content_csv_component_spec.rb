# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ContentCsvComponent, type: :component do
  let(:component) do
    described_class.new(model:, url: '/contents/druid:bc123df4567', download_path: '/contents/abc123/structure/csv',
                        download_label: 'Download it', upload_label: 'Upload it', submit_label: 'Send it',
                        submit_value: 'csv', allow_file_deletion_field:)
  end
  let(:model) { StructuralCsvForm.new }
  let(:allow_file_deletion_field) { false }

  it 'renders the download link and the upload form, which disables actions while uploading' do
    render_inline(component)

    expect(page).to have_link('Download it', href: '/contents/abc123/structure/csv')
    fieldset = page.find('fieldset[data-disable-actions-target="disableable"]')
    form = fieldset.find('form[action="/contents/druid:bc123df4567"]')
    expect(form['data-action']).to include('turbo:submit-start->disable-actions#disable')
    expect(form).to have_field('Upload it', type: 'file')
    expect(form.find_field('Upload it')['accept']).to eq('.csv,.ods,.xlsx')
    expect(form).to have_button('Send it')
    expect(form.find_button('Send it')['value']).to eq('csv')
    expect(form).to have_no_field('Allow files to be deleted')
  end

  context 'with the allow file deletion field' do
    let(:allow_file_deletion_field) { true }

    it 'renders the checkbox' do
      render_inline(component)

      expect(page).to have_unchecked_field('Allow files to be deleted')
    end
  end

  context 'when the upload has errors' do
    let(:model) { StructuralCsvForm.new.tap { |form| form.errors.add(:csv_file, :invalid, message: 'Row 2: Bad') } }

    it 'renders the errors' do
      render_inline(component)

      expect(page).to have_css('.invalid-feedback', text: 'Row 2: Bad')
    end
  end
end
