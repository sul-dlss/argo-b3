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

  describe '#parse_list' do
    it 'returns an array of prefixed druids from a whitespace-separated string' do
      expect(described_class.parse_list("fc245sm0951\ndruid:gh678jk9012  lm345no6789"))
        .to eq(
          ['druid:fc245sm0951', 'druid:gh678jk9012', 'druid:lm345no6789']
        )
    end

    it 'returns an empty array when given a blank string' do
      expect(described_class.parse_list('')).to eq([])
      expect(described_class.parse_list(nil)).to eq([])
    end
  end
end
