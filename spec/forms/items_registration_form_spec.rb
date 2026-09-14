# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemsRegistrationForm do
  describe 'validation of item_registrations' do
    context 'when some item registrations are blank and some are not' do
      let(:form) do
        described_class.new(item_registrations_attributes: [{ title: 'A title' }, {}])
      end

      it 'discards the blank item registrations before validation' do
        form.valid?

        expect(form.item_registrations.map(&:title)).to eq(['A title'])
        expect(form.errors[:item_registrations]).to be_empty
      end
    end

    context 'when every item registration is blank' do
      let(:form) do
        described_class.new(item_registrations_attributes: [{}, {}])
      end

      it 'keeps the blank item registrations and reports a presence error' do
        form.valid?

        expect(form.item_registrations.size).to eq(2)
        expect(form.errors[:item_registrations]).to include('at least one item is required')
      end
    end

    context 'when at least one item registration is not blank' do
      let(:form) do
        described_class.new(item_registrations_attributes: [{ title: 'A title' }])
      end

      it 'does not report a presence error' do
        form.valid?

        expect(form.errors[:item_registrations]).to be_empty
      end
    end
  end

  describe '#invalid_item_registrations' do
    let(:form) do
      described_class.new(
        apo_druid: 'druid:bc123df4567',
        content_type: Cocina::Models::ObjectType.book,
        access_view: 'world',
        access_download: 'world',
        item_registrations_attributes: [
          { source_id: 'sul:1234', title: 'A title' },
          { source_id: 'sul:5678' }
        ]
      )
    end

    it 'returns only the item registrations with errors' do
      form.valid?

      expect(form.invalid_item_registrations.map(&:source_id)).to eq(['sul:5678'])
    end
  end
end
