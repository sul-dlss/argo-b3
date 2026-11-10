# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentTypeSupport do
  describe '.display_name' do
    it 'returns the name selectable on a registration form' do
      expect(described_class.display_name('object')).to eq('file')
      expect(described_class.display_name('book')).to eq('book')
    end

    context 'when the content type is not selectable on a registration form' do
      it 'returns the short name' do
        expect(described_class.display_name('manuscript')).to eq('manuscript')
      end
    end
  end
end
