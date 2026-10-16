# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::StructureButtonComponent, type: :component do
  let(:component) do
    described_class.new(label: 'Append files to structure', commit: ContentStructureController::APPEND_VALUE,
                        populator: 'Book', content_token: 'abc123', content_type: 'https://cocina.sul.stanford.edu/models/book',
                        classes: 'ms-3')
  end

  it 'renders the button with a spinner' do
    render_inline(component)

    action = page.find('div.structure-action.ms-3')
    form = action.find('form[action="/contents/abc123/structure"]')
    expect(form).to have_field('_method', with: 'patch', type: :hidden)
    expect(form).to have_field('commit', with: 'append', type: :hidden)
    expect(form).to have_field('populator', with: 'Book', type: :hidden)
    expect(form).to have_field('content_type', with: 'https://cocina.sul.stanford.edu/models/book', type: :hidden)
    expect(form).to have_button('Append files to structure')
    expect(action).to have_css('.structure-spinner img[src$="/styles/Rosette.svg"]')
    expect(action).to have_text('Structuring files...')
  end
end
