# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LockSupport do
  describe '.bare_lock_from' do
    it 'removes the ETag wrapping' do
      expect(described_class.bare_lock_from('W/"druid:bm430qc7104=2=7"')).to eq('druid:bm430qc7104=2=7')
    end

    it 'removes the ETag wrapping and gzip suffix' do
      expect(described_class.bare_lock_from('W/"druid:bm430qc7104=2=7-gzip"')).to eq('druid:bm430qc7104=2=7')
    end

    it 'returns a bare lock as is' do
      expect(described_class.bare_lock_from('druid:bm430qc7104=2=7')).to eq('druid:bm430qc7104=2=7')
    end

    it 'returns nil when given nil' do
      expect(described_class.bare_lock_from(nil)).to be_nil
    end
  end

  describe '.same?' do
    it 'is true for an ETag lock and the same bare lock' do
      expect(described_class.same?('W/"druid:bm430qc7104=2=7-gzip"', 'druid:bm430qc7104=2=7')).to be true
    end

    it 'is false for different locks' do
      expect(described_class.same?('W/"druid:bm430qc7104=2=7-gzip"', 'druid:bm430qc7104=2=8')).to be false
    end

    it 'is false when a lock is nil' do
      expect(described_class.same?(nil, 'druid:bm430qc7104=2=7')).to be false
    end
  end
end
