# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TokenConcern do
  subject(:including_instance) { controller_class.new }

  let(:controller_class) do
    Class.new do
      include TokenConcern
    end
  end

  let(:value) { 'druid:bc123cd4567' }

  describe '#verifier' do
    it 'returns the argo message verifier' do
      expect(including_instance.verifier).to eq(Rails.application.message_verifier(:argo))
    end
  end

  describe '#generate_token and #verify_token' do
    it 'round-trips a value with default configuration' do
      token = including_instance.generate_token(value)

      expect(including_instance.verify_token(token)).to eq(value)
    end

    it 'uses configured purpose and expires_at builder' do
      expires_at = Time.zone.parse('2026-12-31 23:59:59 UTC')
      controller_class.token_purpose = 'show'
      controller_class.token_expires_at_builder = -> { expires_at }

      token = including_instance.generate_token(value)

      expect(Rails.application.message_verifier(:argo).verify(token, purpose: 'show')).to eq(value)
    end

    it 'raises when token purpose does not match' do
      token = Rails.application.message_verifier(:argo).generate(value, purpose: 'other', expires_at: 1.day.from_now)

      expect { including_instance.verify_token(token) }
        .to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
    end
  end
end
