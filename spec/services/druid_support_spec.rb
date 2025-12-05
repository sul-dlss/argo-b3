# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DruidSupport do
  describe '#bare_druid_from' do
    it 'returns the bare druid when given a druid with prefix' do
      expect(described_class.bare_druid_from('druid:fc245sm0951')).to eq('fc245sm0951')
    end

    it 'returns nil when given nil' do
      expect(described_class.bare_druid_from(nil)).to be_nil
    end

    it 'returns the same string when given a bare druid' do
      expect(described_class.bare_druid_from('fc245sm0951')).to eq('fc245sm0951')
    end
  end

  describe '#prefixed_druid_from' do
    it 'returns the prefixed druid when given a bare druid' do
      expect(described_class.prefixed_druid_from('fc245sm0951')).to eq('druid:fc245sm0951')
    end

    it 'returns nil when given nil' do
      expect(described_class.prefixed_druid_from(nil)).to be_nil
    end

    it 'returns the same string when given a prefixed druid' do
      expect(described_class.prefixed_druid_from('druid:fc245sm0951')).to eq('druid:fc245sm0951')
    end
  end
end
