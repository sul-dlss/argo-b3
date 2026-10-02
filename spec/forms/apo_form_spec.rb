# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApoForm do
  describe '.permitted_params' do
    it 'does not permit the governing APO to be set' do
      expect(described_class.permitted_params).not_to include(:apo_druid)
    end
  end

  describe '#apo_druid' do
    it 'is the uber APO' do
      expect(described_class.new.apo_druid).to eq(Settings.uber_apo_druid)
    end
  end
end
