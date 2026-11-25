# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::StructureButtonComponent, type: :component do
  let(:component) { described_class.new(content_record:) }
  let(:content_record) { create(:content, :mutable, druid: 'druid:bc123df4567') }

  it 'renders the button to structure the files' do
    render_inline(component)

    form = page.find('fieldset[data-disable-actions-target="disableable"] form[action="/contents/druid:bc123df4567"]')
    expect(form).to have_css('input[name="_method"][value="patch"]', visible: :hidden)
    expect(form).to have_css('input[name="commit"][value="restructure"]', visible: :hidden)
    expect(form).to have_button('Structure files', class: 'btn-outline-primary')
  end

  context 'when the files have been structured' do
    before { create(:content_file_set, content: content_record) }

    it 'renders the button to structure the files again' do
      render_inline(component)

      expect(page).to have_button('Clear and structure files again')
    end
  end
end
