# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::FormFooterComponent, type: :component do
  context 'with a cancel path' do
    it 'renders Cancel before the actions' do
      render_inline(described_class.new(cancel_path: '/objects/druid:bc123df4567')) do
        '<button type="submit">Save</button>'.html_safe
      end

      expect(page).to have_css('div.d-flex > a.btn-link:first-child[href="/objects/druid:bc123df4567"]', text: 'Cancel')
      expect(page).to have_css('div.d-flex > a + button', text: 'Save')
    end
  end

  context 'without a cancel path' do
    it 'renders only the actions' do
      render_inline(described_class.new) { '<button type="submit">Impersonate</button>'.html_safe }

      expect(page).to have_no_link('Cancel')
      expect(page).to have_button('Impersonate')
    end
  end
end
