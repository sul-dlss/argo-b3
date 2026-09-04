# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Current do
  describe '#impersonating?' do
    context 'when impersonated groups are present' do
      before do
        described_class.impersonated_groups = ['sdr:group-a']
      end

      it 'returns true' do
        expect(described_class.impersonating?).to be true
      end
    end

    context 'when impersonated groups are blank' do
      before do
        described_class.impersonated_groups = []
      end

      it 'returns false' do
        expect(described_class.impersonating?).to be false
      end
    end
  end
end
