# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImpersonationBannerComponent, type: :component do
  let(:component) { described_class.new }

  context 'when impersonating' do
    before do
      allow(Current).to receive_messages(impersonating?: true, impersonated_groups: %w[sdr:accessioning sdr:developers])
    end

    it 'renders the banner listing the impersonated workgroups' do
      render_inline(component)

      expect(page).to have_css('.impersonation-banner',
                               text: 'Impersonating workgroup(s): sdr:accessioning, sdr:developers')
    end
  end

  context 'when not impersonating' do
    before do
      allow(Current).to receive(:impersonating?).and_return(false)
    end

    it 'does not render the banner' do
      render_inline(component)

      expect(page).to have_no_css('.impersonation-banner')
    end
  end
end
