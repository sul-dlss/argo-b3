# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::Result do
  describe '#valid?' do
    context 'when there are no errors' do
      subject(:result) { described_class.new(warnings: ['A warning.']) }

      it 'is valid' do
        expect(result.valid?).to be true
      end
    end

    context 'when there are errors' do
      subject(:result) { described_class.new(errors: ['An error.']) }

      it 'is not valid' do
        expect(result.valid?).to be false
      end
    end
  end
end
