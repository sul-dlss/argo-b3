# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ContentCsvComponent, type: :component do
  let(:component) do
    described_class.new(model:, url: '/contents/druid:bc123df4567', download_path: '/contents/abc123/structure/csv',
                        i18n_key:, submit_value: 'csv')
  end
  let(:model) { StructuralCsvForm.new }
  let(:i18n_key) { :structural }

  it 'renders an upload form with a download link, which disables actions while uploading' do
    render_inline(component)

    fieldset = page.find('fieldset[data-disable-actions-target="disableable"]')
    form = fieldset.find('form[action="/contents/druid:bc123df4567"]')
    expect(form['data-action']).to include('turbo:submit-start->disable-actions#disable')
    expect(form).to have_link('Download structural metadata CSV', href: '/contents/abc123/structure/csv')
    expect(form.find_link('Download structural metadata CSV')['download']).to be_present
    input = form.find_field('Upload structural metadata CSV', type: 'file')
    expect(input['accept']).to eq('.csv,.ods,.xlsx')
    expect(page.find_by_id(input['aria-describedby']).text)
      .to eq('Replaces all resources and files with those in the CSV. ' \
             'To delete files that the CSV leaves out, select "Allow files to be deleted".')
    expect(form.find_button('Replace structure')['value']).to eq('csv')
  end

  context 'with additional fields' do
    it 'renders them in the upload form, after the file field and before the submit button' do
      render_inline(component) do |content_csv_component|
        content_csv_component.with_additional_fields { '<input type="checkbox" name="extra">'.html_safe }
      end

      inputs = page.all('form input:not([type="hidden"]), form button').map { |input| input['name'] || input['type'] }
      expect(inputs).to eq(['structural_csv[csv_file]', 'extra', 'commit'])
    end
  end

  context 'with the labels copy' do
    let(:model) { LabelsCsvForm.new }
    let(:i18n_key) { :labels }

    it 'renders the labels field, help text, and button' do
      render_inline(component)

      expect(page).to have_link('Download resource labels CSV')
      expect(page).to have_field('Upload resource labels CSV', type: 'file')
      expect(page).to have_text('Changes the labels of the resources listed, matched by sequence.')
      expect(page).to have_button('Change labels')
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
