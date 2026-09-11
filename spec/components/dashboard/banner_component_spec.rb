# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::BannerComponent, type: :component do
  subject(:component) { described_class.new(text:, **options) }

  let(:options) { {} }

  context 'when the banner text is present' do
    let(:text) { 'Welcome to the new Argo application!' }

    it 'renders a dismissible info alert with the banner text' do
      render_inline(component)

      expect(page).to have_css('.alert.alert-info', text:)
      expect(page).to have_css('.alert .btn-close')
    end

    context 'with a custom variant and dismissible: false' do
      let(:options) { { variant: :warning, dismissible: false } }

      it 'renders a non-dismissible alert with the given variant' do
        render_inline(component)

        expect(page).to have_css('.alert.alert-warning', text:)
        expect(page).to have_no_css('.alert .btn-close')
      end
    end
  end

  context 'when the banner text is blank' do
    let(:text) { '' }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_css('.alert')
    end
  end
end
