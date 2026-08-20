# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoToDruidForm do
  subject(:form) { described_class.new(druid:) }

  let(:druid) { 'druid:bc123df4567' }

  before do
    allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_return({})
  end

  it 'is valid when the druid exists' do
    expect(form).to be_valid
  end

  context 'when the druid is blank' do
    let(:druid) { '' }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:druid]).to include('is not a valid druid')
      expect(Sdr::Repository).not_to have_received(:find_solr)
    end
  end

  context 'when the druid is malformed' do
    let(:druid) { 'not-a-druid' }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:druid]).to include('is not a valid druid')
      expect(Sdr::Repository).not_to have_received(:find_solr)
    end
  end

  context 'when the druid does not exist' do
    before do
      allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_raise(Sdr::Repository::NotFoundResponse)
    end

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:druid]).to include('does not exist')
    end
  end
end
