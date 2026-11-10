# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditCollectionForm do
  subject(:edit_collection_form) { described_class.build_from_cocina_object(cocina_object) }

  let(:druid) { 'druid:bc123df4567' }
  let(:apo_druid) { 'druid:hv992ry2431' }
  let(:catalog_links) { [] }
  let(:cocina_object) do
    build(:collection_with_metadata, id: druid, title: 'My collection', admin_policy_id: apo_druid).then do |collection|
      collection.new(access: { view: 'world' },
                     identification: collection.identification.to_h.merge(catalogLinks: catalog_links))
    end
  end

  describe '.build_from_cocina_object' do
    it 'sets the attributes and lock from the cocina object, without changes' do
      expect(edit_collection_form.apo_druid).to eq(apo_druid)
      expect(edit_collection_form.access_view).to eq('world')
      expect(edit_collection_form.lock).to eq(cocina_object.lock)
      expect(edit_collection_form).not_to be_changed
    end
  end

  describe '.permitted_params' do
    it 'does not permit the fields the form does not edit' do
      expect(described_class.permitted_params)
        .not_to include(:source_id, { description_hash: [] }, { tags: [] }, :catalog_link_part_label,
                        :catalog_link_sort_key)
      expect(described_class.permitted_params).to include(:apo_druid, :access_view, :catalog_link_refresh)
    end
  end

  describe 'validation' do
    before { edit_collection_form.update(version_description: 'Updated the description') }

    it 'requires a version description' do
      edit_collection_form.version_description = ''

      expect(edit_collection_form).not_to be_valid
      expect(edit_collection_form.errors[:version_description]).to eq(["can't be blank"])
    end

    it 'requires a FOLIO Instance HRID when Refresh on deposit is checked' do
      edit_collection_form.update(catalog_record_id: '', catalog_link_refresh: true)

      expect(edit_collection_form).not_to be_valid
      expect(edit_collection_form.errors[:catalog_record_id])
        .to eq(['A FOLIO Instance HRID must be provided to allow Refresh on deposit.'])
    end

    it 'allows Refresh on deposit with a FOLIO Instance HRID' do
      allow(CatalogRepository).to receive(:exists?).and_return(true)
      edit_collection_form.update(catalog_record_id: 'a12345', catalog_link_refresh: true)

      expect(edit_collection_form).to be_valid
    end

    it 'requires the APO to be selectable' do
      edit_collection_form.selectable_apo_druids = ['druid:cd234fg5678']

      expect(edit_collection_form).not_to be_valid
      expect(edit_collection_form.errors[:apo_druid]).to eq(['must be an APO you can edit'])
    end
  end

  describe 'description_csv_file' do
    before { edit_collection_form.update(version_description: 'Updated the description', description_csv_file:) }

    let(:description_csv_file) { fixture_file_upload('item_description.csv', 'text/csv') }

    it 'is valid and populates the description from the spreadsheet' do
      expect(edit_collection_form).to be_valid
      expect(edit_collection_form.description_hash[:title].first).to include(value: 'A spreadsheet title')
      expect(edit_collection_form).to be_changed
    end

    context 'when refresh on deposit is checked' do
      let(:catalog_links) { [{ catalog: 'folio', catalogRecordId: 'in111', refresh: true }] }

      it 'is not valid and does not change the description' do
        expect(edit_collection_form).not_to be_valid
        expect(edit_collection_form.errors[:description_csv_file])
          .to eq(['A spreadsheet cannot be uploaded while Refresh on deposit is checked.'])
        expect(edit_collection_form.description_hash).to eq(cocina_object.description.to_h)
      end
    end

    context 'when the spreadsheet is invalid' do
      let(:description_csv_file) { fixture_file_upload('item_description_invalid.csv', 'text/csv') }

      it 'is not valid' do
        expect(edit_collection_form).not_to be_valid
        expect(edit_collection_form.errors[:description_csv_file]).to eq(['Title column not found.'])
      end
    end
  end

  describe '#save!' do
    let(:version_service) { version_service_double(open?: false) }
    let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }

    before do
      edit_collection_form.version_service = version_service
      edit_collection_form.version_description = 'Changed the access'
      allow(Sdr::VersionService).to receive(:open).and_return(opened_cocina_object)
      allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object }
      allow(Sdr::Repository).to receive(:accession)
    end

    it 'opens a version, saves the changes, and starts accessioning' do
      edit_collection_form.access_view = 'dark'
      edit_collection_form.save!(user_name: 'jdoe')

      expect(Sdr::VersionService).to have_received(:open)
        .with(druid:, description: 'Changed the access', opening_user_name: 'jdoe')
      expect(Sdr::Repository).to have_received(:update)
        .with(hash_including(cocina_object: having_attributes(lock: 'opened-lock',
                                                              access: having_attributes(view: 'dark'))))
      expect(Sdr::Repository).to have_received(:accession).with(hash_including(user_name: 'jdoe'))
    end

    it 'opens a version and starts accessioning even without changes' do
      edit_collection_form.save!(user_name: 'jdoe')

      expect(Sdr::VersionService).to have_received(:open)
      expect(Sdr::Repository).not_to have_received(:update)
      expect(Sdr::Repository).to have_received(:accession)
    end
  end
end
