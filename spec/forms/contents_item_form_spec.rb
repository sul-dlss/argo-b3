# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentsItemForm do
  subject(:contents_item_form) { described_class.build_from_cocina_object(cocina_object) }

  let(:cocina_object) do
    build(:dro_with_metadata, type: Cocina::Models::ObjectType.book)
      .then { |dro| dro.new(structural: dro.structural.new(hasMemberOrders: [{ viewingDirection: 'right-to-left' }])) }
  end

  describe '.permitted_params' do
    it 'permits the content type and viewing direction' do
      expect(described_class.permitted_params).to eq(%i[content_type viewing_direction])
    end
  end

  context 'when changing to a content type that has viewing directions' do
    before do
      contents_item_form.update(content_type: Cocina::Models::ObjectType.image)
    end

    it 'retains the viewing direction' do
      expect(contents_item_form).to be_valid
      expect(contents_item_form.viewing_direction).to eq('right-to-left')
    end
  end

  context 'when changing to a content type that does not have viewing directions' do
    before do
      contents_item_form.update(content_type: Cocina::Models::ObjectType.map)
    end

    it 'clears the viewing direction' do
      expect(contents_item_form).to be_valid
      expect(contents_item_form.viewing_direction).to be_nil
    end
  end

  context 'with an invalid viewing direction' do
    before do
      contents_item_form.update(viewing_direction: 'upside-down')
    end

    it 'is not valid' do
      expect(contents_item_form).not_to be_valid
      expect(contents_item_form.errors[:viewing_direction]).to be_present
    end
  end
end
