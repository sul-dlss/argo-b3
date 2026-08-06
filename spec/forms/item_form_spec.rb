# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemForm do
  subject(:item_form) do
    described_class.new(
      source_id: 'new:source-id',
      title:,
      admin_policy_druid: 'druid:bc123df4567',
      content_type: Cocina::Models::ObjectType.object,
      access_view: 'world',
      access_download: 'world'
    )
  end

  let(:title) { 'The Title' }

  describe 'title' do
    context 'when present' do
      it 'is valid' do
        expect(item_form).to be_valid
      end
    end

    context 'when blank' do
      let(:title) { '' }

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:title]).to include("can't be blank")
      end
    end

    context 'when nil' do
      let(:title) { nil }

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.errors[:title]).to include("can't be blank")
      end
    end

    context 'when surrounded by whitespace' do
      let(:title) { '  The Title  ' }

      it 'is normalized by stripping whitespace' do
        expect(item_form.title).to eq('The Title')
      end
    end
  end

  describe 'populate_description_hash' do
    context 'when title is present' do
      it 'sets description_hash from title on validation' do
        item_form.valid?
        expect(item_form.description_hash).to eq(title: [{ value: 'The Title' }])
      end
    end

    context 'when title is blank' do
      let(:title) { nil }

      it 'does not overwrite description_hash' do
        expect { item_form.valid? }.not_to(change(item_form, :description_hash))
      end
    end
  end
end
