# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::ItemDetails do
  subject(:item_details) { described_class.new(content:) }

  let(:druid) { 'druid:bc123df4567' }

  describe '#params' do
    context 'when no item details are saved' do
      let(:content) { build(:content, access_view: 'world') }

      it 'is empty' do
        expect(item_details.params).to eq({})
      end
    end

    context 'when item details are saved' do
      let(:content) do
        build(:content, content_type: 'https://cocina.sul.stanford.edu/models/book', access_view: 'world',
                        version_description: 'Added pages')
      end

      it 'includes the saved item details, including the blank ones' do
        expect(item_details.params).to include(content_type: 'https://cocina.sul.stanford.edu/models/book',
                                               access_view: 'world', access_location: nil,
                                               version_description: 'Added pages')
      end
    end
  end

  describe '#save!' do
    let(:cocina_object) do
      dro = build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
      dro.new(structural: dro.structural.new(hasMemberOrders: [{ viewingDirection: 'right-to-left' }]))
    end
    let(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock) }
    let(:form) do
      ContentsItemForm.build_from_cocina_object(cocina_object).tap do |form|
        form.update(content_type: Cocina::Models::ObjectType.image, perform_speech_to_text: false,
                    version_description: 'Added pages')
      end
    end

    it 'saves the item details and text extraction settings with the content, without saving the object' do
      allow(Sdr::Repository).to receive(:update)

      item_details.save!(form, step: 'files')

      expect(content.reload).to have_attributes(step: 'files', content_type: Cocina::Models::ObjectType.image,
                                                viewing_direction: 'right-to-left', version_description: 'Added pages',
                                                perform_ocr: false)
      expect(Sdr::Repository).not_to have_received(:update)
    end
  end

  describe '#clear!' do
    let(:content) do
      create(:content, druid:, step: 'deposit', content_type: 'https://cocina.sul.stanford.edu/models/book',
                       access_view: 'world', perform_ocr: true)
    end

    it 'clears the item details, keeping the step and the text extraction settings' do
      item_details.clear!

      expect(content.reload).to have_attributes(step: 'deposit', content_type: nil, access_view: nil,
                                                perform_ocr: true)
    end
  end

  describe '#apply_selected_access' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid).new(access: { view: 'world', download: 'world' }) }

    context 'when access is saved' do
      let(:content) { build(:content, content_type: cocina_object.type, access_view: 'dark', access_download: 'none') }

      it 'applies the saved access' do
        expect(item_details.apply_selected_access(cocina_object).access)
          .to have_attributes(view: 'dark', download: 'none')
      end
    end

    context 'when no item details are saved' do
      let(:content) { build(:content) }

      it 'keeps the object access' do
        expect(item_details.apply_selected_access(cocina_object).access).to have_attributes(view: 'world')
      end
    end
  end

  describe '#selected_content_type' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book) }

    context 'when a content type is saved' do
      let(:content) { build(:content, content_type: Cocina::Models::ObjectType.image) }

      it 'is the saved content type' do
        expect(item_details.selected_content_type(cocina_object)).to eq(Cocina::Models::ObjectType.image)
      end
    end

    context 'when no content type is saved' do
      let(:content) { build(:content) }

      it "is the object's content type" do
        expect(item_details.selected_content_type(cocina_object)).to eq(Cocina::Models::ObjectType.book)
      end
    end
  end
end
