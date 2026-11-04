# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Impersonation::Workgroups do
  describe 'WORKGROUPS' do
    it 'is sorted and unique' do
      expect(described_class::WORKGROUPS).to eq(described_class::WORKGROUPS.uniq.sort)
    end
  end

  describe '.from_cookie' do
    let(:cookies) { instance_double(ActionDispatch::Cookies::CookieJar) }
    let(:encrypted_cookie_jar) { instance_double(ActionDispatch::Cookies::CookieJar) }

    before do
      allow(cookies).to receive(:encrypted).and_return(encrypted_cookie_jar)
    end

    context 'when cookie has values' do
      before do
        allow(encrypted_cookie_jar).to receive(:[]).with(:impersonated_workgroups)
                                                   .and_return(['sdr:group-one', '', nil, 'sdr:group-two'])
      end

      it 'returns present groups' do
        expect(described_class.from_cookie(cookies:)).to eq(['sdr:group-one', 'sdr:group-two'])
      end
    end

    context 'when cookie is nil' do
      before do
        allow(encrypted_cookie_jar).to receive(:[]).with(:impersonated_workgroups).and_return(nil)
      end

      it 'returns an empty array' do
        expect(described_class.from_cookie(cookies:)).to eq([])
      end
    end
  end

  describe '.update_cookie' do
    let(:cookies) { instance_double(ActionDispatch::Cookies::CookieJar) }
    let(:encrypted_cookie_jar) { instance_double(ActionDispatch::Cookies::CookieJar) }

    before do
      allow(cookies).to receive(:encrypted).and_return(encrypted_cookie_jar)
      allow(encrypted_cookie_jar).to receive(:[]=)
      allow(cookies).to receive(:delete)
    end

    context 'when groups are present' do
      it 'writes sorted unique groups to encrypted cookie with security options' do
        described_class.update_cookie(cookies:, groups: ['sdr:group-b', nil, 'sdr:group-a', 'sdr:group-b'])

        expect(encrypted_cookie_jar).to have_received(:[]=).with(:impersonated_workgroups, {
                                                                   value: ['sdr:group-a', 'sdr:group-b'],
                                                                   httponly: true,
                                                                   same_site: :lax
                                                                 })
      end
    end

    context 'when groups are blank' do
      it 'clears cookie' do
        described_class.update_cookie(cookies:, groups: ['', nil])

        expect(encrypted_cookie_jar).to have_received(:[]=).with(:impersonated_workgroups, nil)
        expect(cookies).to have_received(:delete).with(:impersonated_workgroups)
      end
    end
  end

  describe '.clear_cookie' do
    let(:cookies) { instance_double(ActionDispatch::Cookies::CookieJar) }
    let(:encrypted_cookie_jar) { instance_double(ActionDispatch::Cookies::CookieJar) }

    before do
      allow(cookies).to receive(:encrypted).and_return(encrypted_cookie_jar)
      allow(encrypted_cookie_jar).to receive(:[]=)
      allow(cookies).to receive(:delete)
    end

    it 'deletes impersonated workgroups cookie' do
      described_class.clear_cookie(cookies:)

      expect(encrypted_cookie_jar).to have_received(:[]=).with(:impersonated_workgroups, nil)
      expect(cookies).to have_received(:delete).with(:impersonated_workgroups)
    end
  end
end
