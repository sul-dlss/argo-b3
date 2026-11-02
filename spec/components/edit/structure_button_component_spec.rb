# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::StructureButtonComponent, type: :component do
  let(:component) do
    described_class.new(label: 'Append files to structure', commit: ContentStructureController::APPEND_VALUE,
                        populator: 'Book', content_token: 'abc123', content_type: 'https://cocina.sul.stanford.edu/models/book',
                        selected_access:, classes: 'ms-3')
  end
  let(:selected_access) { {} }

  it 'renders the button with a spinner' do
    render_inline(component)

    action = page.find('div.structure-action.ms-3')
    form = action.find('form[action="/contents/abc123/structure"]')
    expect(form).to have_field('_method', with: 'patch', type: :hidden)
    expect(form).to have_field('commit', with: 'append', type: :hidden)
    expect(form).to have_field('populator', with: 'Book', type: :hidden)
    expect(form).to have_field('content_type', with: 'https://cocina.sul.stanford.edu/models/book', type: :hidden)
    expect(form).to have_button('Append files to structure')
    expect(form['data-action']).to eq('turbo:submit-start->disable-actions#disable ' \
                                      'turbo:submit-end->disable-actions#enable')
    expect(action).to have_css('.submit-spinner img[src$="/styles/Rosette.svg"]')
    expect(action).to have_text('Structuring files...')
    expect(form).to have_no_field('contents_item', type: :hidden)
  end

  context 'when access has been selected' do
    let(:selected_access) { { 'access_view' => 'dark', 'access_download' => 'none' } }

    it 'renders the selected access' do
      render_inline(component)

      form = page.find('form[action="/contents/abc123/structure"]')
      expect(form).to have_field('contents_item[access_view]', with: 'dark', type: :hidden)
      expect(form).to have_field('contents_item[access_download]', with: 'none', type: :hidden)
    end
  end
end
