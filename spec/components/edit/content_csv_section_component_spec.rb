# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ContentCsvSectionComponent, type: :component do
  let(:component) do
    described_class.new(structural_csv_form:, labels_csv_form:, url: '/contents/druid:bc123df4567',
                        csv_download_path: '/contents/abc123/structure/csv',
                        labels_csv_download_path: '/contents/abc123/structure/labels_csv')
  end
  let(:structural_csv_form) { StructuralCsvForm.new }
  let(:labels_csv_form) { LabelsCsvForm.new }

  def structural_section
    page.find('[data-toggle-section="structural"][data-toggle-target="section"]', visible: :all)
  end

  def labels_section
    page.find('[data-toggle-section="labels"][data-toggle-target="section"]', visible: :all)
  end

  it 'renders a collapsed section with download links and the structural metadata CSV upload selected' do
    render_inline(component)

    toggle = page.find('button.collapsible-section-toggle', text: 'Use a spreadsheet')
    expect(toggle['aria-expanded']).to eq('false')
    expect(toggle['aria-controls']).to eq('use-a-spreadsheet')

    section = page.find_by_id('use-a-spreadsheet', visible: :all)
    csv_link = section.find_link('Download Structural metadata CSV', href: '/contents/abc123/structure/csv',
                                                                     visible: :all)
    expect(csv_link['download']).to be_present
    labels_link = section.find_link('Download Labels CSV', href: '/contents/abc123/structure/labels_csv', visible: :all)
    expect(labels_link['download']).to be_present

    expect(section).to have_field('Structural metadata CSV', type: 'radio', checked: true, visible: :all)
    expect(section).to have_field('Labels CSV', type: 'radio', checked: false, visible: :all)
    expect(structural_section[:class].to_s).not_to include('d-none')
    expect(labels_section[:class].to_s).to include('d-none')
  end

  it 'renders the structural metadata CSV upload form, which disables actions while uploading' do
    render_inline(component)

    fieldset = structural_section.find('fieldset[data-disable-actions-target="disableable"]', visible: :all)
    form = fieldset.find('form[action="/contents/druid:bc123df4567"]', visible: :all)
    expect(form['data-action']).to include('turbo:submit-start->disable-actions#disable')
    input = form.find_field('Structural metadata CSV file', type: 'file', visible: :all)
    expect(input['accept']).to eq('.csv,.ods,.xlsx')
    expect(page.find_by_id(input['aria-describedby'], visible: :all).text)
      .to eq('Replaces all resources and files with those in the CSV. ' \
             'To delete files that the CSV leaves out, select "Allow files to be deleted".')
    inputs = form.all('input:not([type="hidden"]), button', visible: :all).pluck('name')
    expect(inputs).to eq(['structural_csv[csv_file]', 'structural_csv[allow_file_deletion]', 'commit'])
    expect(form.find_button('Structure files', visible: :all)['value']).to eq('csv')
  end

  it 'renders the labels CSV upload form, without the allow files to be deleted checkbox' do
    render_inline(component)

    form = labels_section.find('fieldset[data-disable-actions-target="disableable"] form', visible: :all)
    expect(form['action']).to eq('/contents/druid:bc123df4567')
    expect(form['data-action']).to include('turbo:submit-start->disable-actions#disable')
    input = form.find_field('Labels CSV file', type: 'file', visible: :all)
    expect(page.find_by_id(input['aria-describedby'], visible: :all).text)
      .to eq('Changes the labels of the resources listed, matched by sequence.')
    inputs = form.all('input:not([type="hidden"]), button', visible: :all).pluck('name')
    expect(inputs).to eq(['labels_csv[csv_file]', 'commit'])
    expect(form.find_button('Structure files', visible: :all)['value']).to eq('labels_csv')
  end

  it 'keeps the toggle out of the upload forms, so that its value is not submitted, and disables it while uploading' do
    render_inline(component)

    expect(page).to have_no_css('form input[type="radio"]', visible: :all)
    expect(page).to have_css('fieldset[data-disable-actions-target="disableable"] input[type="radio"]', count: 2,
                                                                                                        visible: :all)
  end

  context 'when the structural metadata CSV upload has errors' do
    let(:structural_csv_form) do
      StructuralCsvForm.new.tap { |form| form.errors.add(:csv_file, :invalid, message: 'Row 2: Bad') }
    end

    it 'renders the section expanded, with the structural metadata CSV selected and its errors' do
      render_inline(component)

      expect(page.find('button.collapsible-section-toggle')['aria-expanded']).to eq('true')
      expect(page).to have_field('Structural metadata CSV', type: 'radio', checked: true)
      expect(labels_section[:class].to_s).to include('d-none')
      expect(structural_section).to have_css('.invalid-feedback', text: 'Row 2: Bad')
    end
  end

  context 'when the labels CSV upload has errors' do
    let(:labels_csv_form) do
      LabelsCsvForm.new.tap { |form| form.errors.add(:csv_file, :invalid, message: 'Row 3: Bad') }
    end

    it 'renders the section expanded, with the labels CSV selected and its errors' do
      render_inline(component)

      expect(page.find('button.collapsible-section-toggle')['aria-expanded']).to eq('true')
      expect(page).to have_field('Labels CSV', type: 'radio', checked: true)
      expect(structural_section[:class].to_s).to include('d-none')
      expect(labels_section[:class].to_s).not_to include('d-none')
      expect(labels_section).to have_css('.invalid-feedback', text: 'Row 3: Bad')
    end
  end
end
