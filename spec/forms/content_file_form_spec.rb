# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentFileForm do
  describe '.from_model' do
    subject(:form) { described_class.from_model(content_file) }

    {
      { publish: true, preserve: true } => 'publish_and_preserve',
      { publish: true, preserve: false } => 'publish_only',
      { publish: false, preserve: true } => 'preserve_only'
    }.each do |attributes, administrative|
      context "when publish is #{attributes[:publish]} and preserve is #{attributes[:preserve]}" do
        let(:content_file) { build(:content_file, **attributes) }

        it "maps to #{administrative}" do
          expect(form.administrative).to eq(administrative)
        end
      end
    end
  end
end
