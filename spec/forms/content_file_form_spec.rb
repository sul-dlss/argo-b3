# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentFileForm do
  subject(:form) do
    described_class.new(publish:, preserve:, mime_type: 'image/tiff', view: 'world', download: 'world')
  end

  [[true, false], [false, true], [true, true]].each do |publish_value, preserve_value|
    context "when publish is #{publish_value} and preserve is #{preserve_value}" do
      let(:publish) { publish_value }
      let(:preserve) { preserve_value }

      it 'is valid' do
        expect(form).to be_valid
      end
    end
  end

  context 'when neither publish nor preserve is selected' do
    let(:publish) { false }
    let(:preserve) { false }

    it 'is invalid with an error on publish' do
      expect(form).not_to be_valid
      expect(form.errors[:publish]).to eq(['Select publish, preserve, or both.'])
    end
  end
end
