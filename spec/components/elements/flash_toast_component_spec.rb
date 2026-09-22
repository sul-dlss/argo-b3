# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::FlashToastComponent, type: :component do
  context 'when there is a toast flash' do
    before do
      vc_test_controller.flash[:toast] = 'Saved'
    end

    it 'renders a turbo stream that appends the toast' do
      render_inline(described_class.new)

      expect(page).to have_css('turbo-stream[action="append"][target="toast-container"]')
      expect(rendered_content).to include('Saved')
    end
  end

  context 'when there is no toast flash' do
    it 'does not render' do
      render_inline(described_class.new)

      expect(page).to have_no_css('turbo-stream')
    end
  end
end
