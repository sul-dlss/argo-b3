# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditAgreementForm do
  subject(:edit_agreement_form) { described_class.build_from_cocina_object(cocina_object) }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) do
    build(:agreement_with_metadata, id: druid, title: 'My agreement', source_id: 'sul:agreement-1').new(
      description: {
        title: [{ value: 'My agreement' }],
        note: [{ value: 'An agreement note' }],
        purl: 'https://purl.stanford.edu/bc123df4567'
      }
    )
  end

  describe '.build_from_cocina_object' do
    it 'sets the title and source id from the cocina object, without changes' do
      expect(edit_agreement_form).to have_attributes(title: 'My agreement', source_id: 'sul:agreement-1')
      expect(edit_agreement_form).not_to be_changed
    end
  end

  describe '.permitted_params' do
    it 'permits only the title, source id, version description, and lock' do
      expect(described_class.permitted_params).to contain_exactly(:title, :source_id, :version_description, :lock)
    end
  end

  describe 'validation' do
    before do
      allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
      edit_agreement_form.version_description = 'Changed the title'
    end

    it 'is valid with a title, source id, and version description' do
      expect(edit_agreement_form).to be_valid
    end

    context 'without a title' do
      before { edit_agreement_form.title = '' }

      it 'is not valid' do
        expect(edit_agreement_form).not_to be_valid
        expect(edit_agreement_form.errors[:title]).to include("can't be blank")
      end
    end

    context 'when the source id is changed to one that already exists' do
      before do
        allow(Sdr::Repository).to receive(:source_id_exists?).and_return(true)
        edit_agreement_form.source_id = 'sul:agreement-2'
      end

      it 'is not valid' do
        expect(edit_agreement_form).not_to be_valid
        expect(edit_agreement_form.errors[:source_id]).to include('already exists')
      end
    end

    context 'when depositing files that have unsaved changes' do
      before do
        content = create(:content, :mutable, druid:, lock: cocina_object.lock)
        # A file that has not been staged is an unsaved change.
        create(:content_file_binary, content:, file_location: 'attached')
        edit_agreement_form.content = content
      end

      it 'is not valid when depositing' do
        expect(edit_agreement_form.valid?(:deposit)).to be false
        expect(edit_agreement_form.errors[:content])
          .to eq(['Files have unsaved changes. Save or deposit them from Manage files.'])
      end

      it 'is valid when not depositing' do
        expect(edit_agreement_form).to be_valid
      end
    end
  end

  describe '#save!' do
    let(:user_name) { 'test_user' }
    let(:version_service) { version_service_double(open?: false, openable?: true, closeable?: false, closed?: true) }
    let(:opened_cocina_object) { cocina_object.new(version: 2) }

    before do
      allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
      allow(Sdr::VersionService).to receive(:open).and_return(opened_cocina_object)
      allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object }
      allow(Sdr::Repository).to receive(:accession)
      edit_agreement_form.version_service = version_service
      edit_agreement_form.update(title: 'My new agreement', source_id: 'sul:agreement-2',
                                 version_description: 'Changed the title')
    end

    it 'opens a version and saves the title and source id, retaining the rest of the description and access' do
      edit_agreement_form.save!(user_name:)

      expect(Sdr::VersionService).to have_received(:open)
        .with(druid:, description: 'Changed the title', opening_user_name: user_name)
      expect(Sdr::Repository).to have_received(:update) do |args|
        updated_cocina_object = args[:cocina_object]
        expect(updated_cocina_object).to have_attributes(version: 2, type: Cocina::Models::ObjectType.agreement)
        expect(updated_cocina_object.identification.sourceId).to eq('sul:agreement-2')
        expect(updated_cocina_object.description.title.first.value).to eq('My new agreement')
        expect(updated_cocina_object.description.note.first.value).to eq('An agreement note')
        expect(updated_cocina_object.administrative.hasAdminPolicy).to eq('druid:hv992ry2431')
        expect(updated_cocina_object.access).to have_attributes(view: 'dark', download: 'none')
      end
      expect(Sdr::Repository).not_to have_received(:accession)
    end

    context 'when depositing with content' do
      let(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock) }

      before { edit_agreement_form.content = content }

      it 'saves, accessions, and destroys the mutable content' do
        edit_agreement_form.save!(user_name:, accession: true)

        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: having_attributes(version: 2), user_name:, context: {})
        expect(Content.exists?(content.id)).to be false
      end
    end
  end
end
