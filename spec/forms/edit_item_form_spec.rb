# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditItemForm do
  subject(:edit_item_form) { described_class.build_from_cocina_object(cocina_object) }

  let(:cocina_object) { unembargoed_cocina_object }
  let(:unembargoed_cocina_object) do
    build(:dro_with_metadata, id: 'druid:bc123df4567', type: Cocina::Models::ObjectType.book)
  end
  let(:embargoed_cocina_object) do
    embargo = { releaseDate: '2030-01-01T00:00:00Z', view: 'world', download: 'world' }
    unembargoed_cocina_object.new(access: { view: 'stanford', download: 'stanford', embargo: })
  end

  describe '.build_from_cocina_object' do
    it 'sets the lock from the cocina object' do
      expect(edit_item_form.lock).to eq(cocina_object.lock)
    end

    context 'without an embargo' do
      it 'is without embargo' do
        expect(edit_item_form.with_embargo).to be false
        expect(edit_item_form).not_to be_changed
      end
    end

    context 'with an embargo' do
      let(:cocina_object) { embargoed_cocina_object }

      it 'is with embargo' do
        expect(edit_item_form.with_embargo).to be true
        expect(edit_item_form.embargo_release_date).to eq(Time.zone.parse('2030-01-01'))
        expect(edit_item_form).not_to be_changed
      end
    end
  end

  describe 'embargo' do
    before { edit_item_form.version_description = 'Changed the embargo' }

    context 'when the embargo is removed' do
      let(:cocina_object) { embargoed_cocina_object }

      before { edit_item_form.update(with_embargo: false) }

      it 'clears the embargo when validated' do
        expect(edit_item_form).to be_valid
        expect(edit_item_form.embargo_release_date).to be_nil
        expect(edit_item_form.embargo_view).to be_nil
        expect(edit_item_form).to be_changed
      end
    end

    context 'when an embargo is added without a release date' do
      before { edit_item_form.update(with_embargo: true) }

      it 'is not valid' do
        expect(edit_item_form).not_to be_valid
        expect(edit_item_form.errors[:embargo_release_date]).to include("can't be blank")
      end
    end
  end

  describe 'collections' do
    it 'removes the blank value submitted by the multiple select' do
      edit_item_form.update(collection_druids: ['', 'druid:bc123df4567'])

      expect(edit_item_form.collection_druids).to eq(['druid:bc123df4567'])
    end
  end

  describe 'version description validation' do
    context 'without a version description' do
      it 'is not valid' do
        expect(edit_item_form).not_to be_valid
        expect(edit_item_form.errors[:version_description]).to include("can't be blank")
      end
    end

    context 'with a version description' do
      before { edit_item_form.version_description = 'Fixed the content type' }

      it 'is valid' do
        expect(edit_item_form).to be_valid
      end
    end
  end

  describe '#changed?' do
    context 'when only the version description changed' do
      before { edit_item_form.update(version_description: 'Fixed the content type') }

      it 'returns false' do
        expect(edit_item_form).not_to be_changed
      end
    end

    context 'when only the lock changed' do
      before { edit_item_form.update(lock: 'other-lock') }

      it 'returns false' do
        expect(edit_item_form).not_to be_changed
      end
    end

    context 'when only the attributes that control the form changed' do
      before { edit_item_form.update(with_embargo: true, limit_collection_by_apo: true) }

      it 'returns false' do
        expect(edit_item_form).not_to be_changed
      end
    end

    context 'when an attribute of the cocina object changed' do
      before { edit_item_form.update(content_type: Cocina::Models::ObjectType.image) }

      it 'returns true' do
        expect(edit_item_form).to be_changed
      end
    end
  end

  describe '#save!' do
    let(:user_name) { 'jlittman' }
    let(:version_service) do
      version_service_double(open?: open, version_description: 'Fixed the content type')
    end
    let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }

    before do
      allow(Sdr::VersionService).to receive_messages(new: version_service, open: opened_cocina_object)
      allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object }
      allow(Sdr::Repository).to receive(:accession)
    end

    context 'when the version is open and the version description changed' do
      let(:open) { true }

      before { edit_item_form.update(version_description: 'Fixed the content type and title') }

      it 'updates the version description without opening a version' do
        edit_item_form.save!(user_name:)

        expect(Sdr::VersionService).to have_received(:new).with(druid: 'druid:bc123df4567')
        expect(version_service).to have_received(:update_description)
          .with(description: 'Fixed the content type and title', user_name:)
        expect(Sdr::VersionService).not_to have_received(:open)
      end
    end

    context 'when the version is open and the version description did not change' do
      let(:open) { true }

      before do
        edit_item_form.update(version_description: 'Fixed the content type',
                              content_type: Cocina::Models::ObjectType.image)
      end

      it 'saves without updating the version description' do
        edit_item_form.save!(user_name:)

        expect(version_service).not_to have_received(:update_description)
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).to have_received(:update)
      end
    end

    context 'when the version is closed and there are changes' do
      let(:open) { false }

      before do
        edit_item_form.update(version_description: 'Changed type', content_type: Cocina::Models::ObjectType.image)
      end

      it 'opens a new version and saves against it' do
        edit_item_form.save!(user_name:)

        expect(Sdr::VersionService).to have_received(:open)
          .with(druid: cocina_object.externalIdentifier, description: 'Changed type', opening_user_name: user_name)
        expect(Sdr::Repository).to have_received(:update)
          .with(cocina_object: having_attributes(version: 2, lock: 'opened-lock'), user_name:, description: nil)
        expect(version_service).not_to have_received(:update_description)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when the version is closed and there are no changes' do
      let(:open) { false }

      before { edit_item_form.update(version_description: 'Nothing really') }

      it 'neither opens a version nor saves' do
        edit_item_form.save!(user_name:)

        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when accessioning with a closed version and no changes' do
      let(:open) { false }

      before { edit_item_form.update(version_description: 'Redeposit') }

      it 'opens a new version and starts accessioning it' do
        edit_item_form.save!(user_name:, accession: true)

        expect(Sdr::VersionService).to have_received(:open)
          .with(druid: cocina_object.externalIdentifier, description: 'Redeposit', opening_user_name: user_name)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: opened_cocina_object, user_name:, context: {})
      end
    end

    context 'when accessioning with a content that has OCR settings' do
      let(:open) { true }
      let(:content) do
        create(:content, druid: cocina_object.externalIdentifier, lock: cocina_object.lock, immutable: false,
                         perform_ocr: true, ocr_languages: ['English'])
      end

      before do
        edit_item_form.update(version_description: 'Fixed the content type',
                              content_type: Cocina::Models::ObjectType.image)
        edit_item_form.content = content
        allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object.new(lock: 'updated-lock') }
      end

      it 'starts accessioning with the OCR settings and destroys the content' do
        edit_item_form.save!(user_name:, accession: true)

        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: having_attributes(lock: 'updated-lock'), user_name:,
                context: { runOcr: true, ocrLanguages: ['English'] })
        expect(Content.exists?(content.id)).to be false
      end
    end

    context 'when accessioning fails with a content' do
      let(:open) { true }
      let(:content) do
        create(:content, druid: cocina_object.externalIdentifier, lock: cocina_object.lock, immutable: false,
                         perform_ocr: true, ocr_languages: ['English'])
      end

      before do
        allow(Sdr::Repository).to receive(:accession).and_raise(Sdr::Repository::Error, 'Accession failed')
        edit_item_form.update(version_description: 'Redeposit')
        edit_item_form.content = content
      end

      it 'keeps the content with its OCR settings' do
        expect { edit_item_form.save!(user_name:, accession: true) }.to raise_error(Sdr::Repository::Error)
        expect(content.reload).to have_attributes(lock: cocina_object.lock, perform_ocr: true)
      end
    end

    context 'when saving fails with a content' do
      let(:open) { false }
      let(:content) do
        create(:content, druid: cocina_object.externalIdentifier, lock: cocina_object.lock, immutable: false)
      end

      before do
        allow(Sdr::Repository).to receive(:update).and_raise(Sdr::Repository::Error, 'Update failed')
        edit_item_form.update(version_description: 'Changed type', content_type: Cocina::Models::ObjectType.image)
        edit_item_form.content = content
      end

      it 'rebases the content onto the opened version' do
        expect { edit_item_form.save!(user_name:) }.to raise_error(Sdr::Repository::Error)
        expect(content.reload.lock).to eq('opened-lock')
      end
    end

    context 'without a version description' do
      let(:open) { false }

      before { edit_item_form.update(content_type: Cocina::Models::ObjectType.image) }

      it 'raises without opening a version' do
        expect { edit_item_form.save!(user_name:) }.to raise_error(ActiveModel::ValidationError)
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end
  end
end
