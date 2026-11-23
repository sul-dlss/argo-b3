# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DepositDraftForm do
  describe '.for_status' do
    let(:version_service) { version_service_double(version_description: 'Fixed the title') }

    it 'prefills the open version description' do
      form = described_class.for_status(version_service:)

      expect(form.version_description).to eq('Fixed the title')
    end
  end
end
