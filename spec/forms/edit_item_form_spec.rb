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

  describe 'description_csv_file' do
    before { edit_item_form.update(version_description: 'Updated the description', description_csv_file:) }

    context 'when a valid spreadsheet is provided' do
      let(:description_csv_file) { fixture_file_upload('item_description.csv', 'text/csv') }

      it 'is valid and populates the description from the spreadsheet' do
        expect(edit_item_form).to be_valid
        expect(edit_item_form.description_hash[:title].first).to include(value: 'A spreadsheet title')
        expect(edit_item_form.description_hash[:note].first).to include(value: 'A note', type: 'summary')
        expect(edit_item_form).to be_changed
      end
    end

    context 'when a spreadsheet is provided while refresh on deposit is checked' do
      let(:cocina_object) do
        catalog_links = [{ catalog: 'folio', catalogRecordId: 'in111', refresh: true }]
        unembargoed_cocina_object.then do |dro|
          dro.new(identification: dro.identification.to_h.merge(catalogLinks: catalog_links))
        end
      end
      let(:description_csv_file) { fixture_file_upload('item_description.csv', 'text/csv') }

      it 'is not valid and does not change the description' do
        expect(edit_item_form).not_to be_valid
        expect(edit_item_form.errors[:description_csv_file])
          .to eq(['A spreadsheet cannot be uploaded while Refresh on deposit is checked.'])
        expect(edit_item_form.description_hash).to eq(cocina_object.description.to_h)
      end
    end

    context 'when the spreadsheet has the same description' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: 'druid:bc123df4567', title: 'A spreadsheet title')
      end
      let(:description_csv_file) { fixture_file_upload('item_description_title_only.csv', 'text/csv') }

      it 'is valid and not changed' do
        expect(edit_item_form).to be_valid
        expect(edit_item_form).not_to be_changed
      end
    end

    context 'when no spreadsheet is provided' do
      let(:description_csv_file) { nil }

      it 'is valid and does not change the description' do
        expect(edit_item_form).to be_valid
        expect(edit_item_form.description_hash).to eq(cocina_object.description.to_h)
        expect(edit_item_form).not_to be_changed
      end
    end

    context 'when the spreadsheet is not valid' do
      let(:description_csv_file) { fixture_file_upload('item_description_invalid.csv', 'text/csv') }

      it 'is not valid and does not change the description' do
        expect(edit_item_form).not_to be_valid
        expect(edit_item_form.errors[:description_csv_file]).to eq(['Title column not found.'])
        expect(edit_item_form.description_hash).to eq(cocina_object.description.to_h)
      end
    end

    context 'when the spreadsheet has more than one row' do
      let(:description_csv_file) { fixture_file_upload('item_description_multiple_rows.csv', 'text/csv') }

      it 'is not valid' do
        expect(edit_item_form).not_to be_valid
        expect(edit_item_form.errors[:description_csv_file]).to eq(['Only one row of description is allowed.'])
      end
    end

    context 'when the spreadsheet cannot be read' do
      let(:description_csv_file) { fixture_file_upload('catalog_record_id_and_barcode.xls') }

      it 'is not valid' do
        expect(edit_item_form).not_to be_valid
        expect(edit_item_form.errors[:description_csv_file]).to eq(['Unsupported upload file type'])
      end
    end
  end

  describe 'catalog record id' do
    let(:cocina_object) do
      catalog_links = [{ catalog: 'folio', catalogRecordId: 'in111', refresh: false },
                       { catalog: 'folio', catalogRecordId: 'in222', refresh: true, partLabel: 'v. 1' }]
      unembargoed_cocina_object.then do |dro|
        dro.new(identification: dro.identification.to_h.merge(catalogLinks: catalog_links))
      end
    end

    before { allow(CatalogRepository).to receive(:exists?).and_return(true) }

    it 'is prefilled from the refreshing Folio catalog link, with the other links as additional' do
      expect(edit_item_form).to have_attributes(catalog_record_id: 'in222', catalog_link_refresh: true)
      expect(edit_item_form.additional_folio_catalog_links.map(&:catalog_record_id)).to eq(%w[in111])
      expect(edit_item_form).not_to be_changed
    end

    context 'when unchanged' do
      it 'keeps the Folio catalog links' do
        edit_item_form.valid?

        expect(edit_item_form.folio_catalog_links.map(&:catalog_record_id)).to eq(%w[in222 in111])
        expect(edit_item_form).not_to be_changed
        expect(CatalogRepository).not_to have_received(:exists?)
      end
    end

    context 'when changed' do
      it 'replaces the first Folio catalog link' do
        edit_item_form.update(catalog_record_id: 'in333')
        edit_item_form.valid?

        expect(edit_item_form.folio_catalog_links.map(&:catalog_record_id)).to eq(%w[in333 in111])
        expect(edit_item_form).to be_changed
      end
    end

    context 'when changed to a catalog record id not found in FOLIO' do
      before do
        allow(CatalogRepository).to receive(:exists?).with(catalog_record_id: 'in999',
                                                           allow_catalog_errors: true).and_return(false)
      end

      it 'is invalid' do
        edit_item_form.update(catalog_record_id: 'in999')

        expect(edit_item_form).not_to be_valid
        expect(edit_item_form.errors[:catalog_record_id]).to eq(['was not found in FOLIO'])
      end
    end

    context 'when swapped with an additional catalog record id' do
      it 'makes the additional link the first and is changed' do
        edit_item_form.update(version_description: 'Fixed the HRIDs', catalog_record_id: 'in111',
                              additional_folio_catalog_links_attributes: [{ catalog_record_id: 'in222' }])

        expect(edit_item_form).to be_valid
        expect(edit_item_form.folio_catalog_links.map(&:catalog_record_id)).to eq(%w[in111 in222])
        expect(edit_item_form).to be_changed
        expect(CatalogRepository).not_to have_received(:exists?)
      end
    end

    context 'when changed to another of the Folio catalog links' do
      it 'makes that link the first without duplicating it' do
        edit_item_form.update(catalog_record_id: 'in111')
        edit_item_form.valid?

        expect(edit_item_form.folio_catalog_links.map(&:catalog_record_id)).to eq(%w[in111])
      end
    end

    context 'when cleared with additional catalog record ids' do
      it 'is invalid' do
        edit_item_form.update(catalog_record_id: '')

        expect(edit_item_form).not_to be_valid
        expect(edit_item_form.errors[:catalog_record_id]).to eq(['Enter a FOLIO Instance HRID.'])
      end
    end

    context 'when cleared with the additional catalog record ids and part label' do
      it 'removes the Folio catalog links' do
        edit_item_form.update(version_description: 'Fixed the HRIDs', catalog_record_id: '',
                              catalog_link_part_label: '',
                              additional_folio_catalog_links_attributes: [{ catalog_record_id: '' }])

        expect(edit_item_form).to be_valid
        expect(edit_item_form.folio_catalog_links).to be_empty
        expect(edit_item_form).to be_changed
      end
    end

    context 'when additional catalog record ids are added, edited, and removed' do
      it 'replaces the additional Folio catalog links' do
        edit_item_form.update(version_description: 'Fixed the HRIDs', additional_folio_catalog_links_attributes: {
                                '0' => { catalog_record_id: 'in333' },
                                '1' => { catalog_record_id: ' in444 ' },
                                '2' => { catalog_record_id: '' },
                                '3' => { catalog_record_id: 'in222' }
                              })

        expect(edit_item_form).to be_valid
        expect(edit_item_form.folio_catalog_links.map(&:catalog_record_id)).to eq(%w[in222 in333 in444])
        expect(edit_item_form).to be_changed
        expect(CatalogRepository).to have_received(:exists?).with(catalog_record_id: 'in333',
                                                                  allow_catalog_errors: true)
        expect(CatalogRepository).to have_received(:exists?).with(catalog_record_id: 'in444',
                                                                  allow_catalog_errors: true)
        expect(CatalogRepository).to have_received(:exists?).twice
      end
    end

    context 'when an additional catalog record id is not found in FOLIO' do
      before do
        allow(CatalogRepository).to receive(:exists?).with(catalog_record_id: 'in999',
                                                           allow_catalog_errors: true).and_return(false)
      end

      it 'is invalid' do
        edit_item_form.update(additional_folio_catalog_links_attributes: [{ catalog_record_id: 'in111' },
                                                                          { catalog_record_id: 'in999' }])

        expect(edit_item_form).not_to be_valid
        expect(edit_item_form.errors['additional_folio_catalog_links[1].catalog_record_id'])
          .to eq(['was not found in FOLIO'])
      end
    end

    context 'when added to an item without Folio catalog links' do
      let(:cocina_object) { unembargoed_cocina_object }

      it 'adds a Folio catalog link' do
        expect(edit_item_form.catalog_record_id).to be_nil

        edit_item_form.update(catalog_record_id: 'in333')
        edit_item_form.valid?

        expect(edit_item_form.folio_catalog_links.map(&:catalog_record_id)).to eq(%w[in333])
        expect(edit_item_form).to be_changed
      end
    end

    context 'when the part label and sort key are changed' do
      it 'is changed' do
        edit_item_form.update(catalog_link_part_label: ' v. 2 ', catalog_link_sort_key: '2')

        expect(edit_item_form).to have_attributes(catalog_link_part_label: 'v. 2', catalog_link_sort_key: '2')
        expect(edit_item_form).to be_changed
      end
    end

    context 'when a part label is entered without a catalog record id' do
      let(:cocina_object) { unembargoed_cocina_object }

      it 'is invalid' do
        edit_item_form.update(version_description: 'Fixed the part label', catalog_link_part_label: 'v. 1')

        expect(edit_item_form).not_to be_valid
        expect(edit_item_form.errors[:catalog_record_id]).to eq(['Enter a FOLIO Instance HRID.'])
      end
    end

    context 'when the serials and barcode fields are submitted blank for an item without them' do
      let(:cocina_object) { unembargoed_cocina_object }

      it 'is not changed' do
        edit_item_form.update(barcode: '', catalog_link_part_label: '', catalog_link_sort_key: ' ')

        expect(edit_item_form).to have_attributes(barcode: nil, catalog_link_part_label: nil,
                                                  catalog_link_sort_key: nil)
        expect(edit_item_form).not_to be_changed
      end
    end

    context 'when only the refresh setting changed' do
      it 'is changed' do
        edit_item_form.update(catalog_link_refresh: false)

        expect(edit_item_form).to be_changed
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

    context 'when a description spreadsheet is provided' do
      let(:open) { true }

      before do
        edit_item_form.update(version_description: 'Fixed the content type',
                              description_csv_file: fixture_file_upload('item_description.csv', 'text/csv'))
      end

      it 'saves the description from the spreadsheet' do
        edit_item_form.save!(user_name:)

        expect(Sdr::Repository).to have_received(:update)
          .with(cocina_object: having_attributes(description: having_attributes(
            title: [having_attributes(value: 'A spreadsheet title')],
            note: [having_attributes(value: 'A note', type: 'summary')],
            purl: 'https://purl.stanford.edu/bc123df4567'
          )), user_name:, description: nil)
      end
    end

    context 'when the catalog record id and refresh setting are changed' do
      let(:open) { true }
      let(:cocina_object) do
        unembargoed_cocina_object.then do |dro|
          dro.new(identification: dro.identification.to_h.merge(catalogLinks: [
                                                                  { catalog: 'folio', catalogRecordId: 'in111',
                                                                    refresh: true }
                                                                ]))
        end
      end

      before do
        allow(CatalogRepository).to receive(:exists?).and_return(true)
        edit_item_form.update(version_description: 'Fixed the content type', catalog_record_id: 'in333',
                              catalog_link_refresh: false)
      end

      it 'saves the catalog links' do
        edit_item_form.save!(user_name:)

        expect(CatalogRepository).to have_received(:exists?).with(catalog_record_id: 'in333',
                                                                  allow_catalog_errors: true)

        expect(Sdr::Repository).to have_received(:update) do |cocina_object:, **|
          expect(cocina_object.identification.catalogLinks.map(&:to_h)).to contain_exactly(
            { catalog: 'folio', catalogRecordId: 'in333', refresh: false },
            { catalog: 'previous folio', catalogRecordId: 'in111', refresh: false }
          )
        end
      end
    end

    context 'when the catalog record id is swapped with an additional catalog record id' do
      let(:open) { true }
      let(:cocina_object) do
        catalog_links = [
          { catalog: 'folio', catalogRecordId: 'in111', refresh: true, partLabel: 'v. 1', sortKey: '1' },
          { catalog: 'folio', catalogRecordId: 'in222', refresh: false }
        ]
        unembargoed_cocina_object.then do |dro|
          dro.new(identification: dro.identification.to_h.merge(catalogLinks: catalog_links))
        end
      end

      before do
        edit_item_form.update(version_description: 'Fixed the HRIDs', catalog_record_id: 'in222',
                              additional_folio_catalog_links_attributes: [{ catalog_record_id: 'in111' }])
      end

      it 'moves the refresh setting and serials to the new first Folio catalog link' do
        edit_item_form.save!(user_name:)

        expect(Sdr::Repository).to have_received(:update) do |cocina_object:, **|
          expect(cocina_object.identification.catalogLinks.map(&:to_h)).to eq(
            [{ catalog: 'folio', catalogRecordId: 'in222', refresh: true, partLabel: 'v. 1', sortKey: '1' },
             { catalog: 'folio', catalogRecordId: 'in111', refresh: false }]
          )
        end
      end
    end

    context 'when the barcode and serials are changed' do
      let(:open) { true }
      let(:cocina_object) do
        unembargoed_cocina_object.then do |dro|
          dro.new(identification: dro.identification.to_h.merge(
            catalogLinks: [{ catalog: 'folio', catalogRecordId: 'in111', refresh: true }]
          ))
        end
      end

      before do
        edit_item_form.update(version_description: 'Fixed the content type', barcode: '36105010362304',
                              catalog_link_part_label: 'v. 1', catalog_link_sort_key: '1')
      end

      it 'saves the barcode and the serials on the Folio catalog link' do
        edit_item_form.save!(user_name:)

        expect(Sdr::Repository).to have_received(:update) do |cocina_object:, **|
          expect(cocina_object.identification.barcode).to eq('36105010362304')
          expect(cocina_object.identification.catalogLinks.map(&:to_h)).to eq(
            [{ catalog: 'folio', catalogRecordId: 'in111', refresh: true, partLabel: 'v. 1', sortKey: '1' }]
          )
        end
      end
    end

    context 'when an additional catalog record id is added' do
      let(:open) { true }
      let(:cocina_object) do
        unembargoed_cocina_object.then do |dro|
          dro.new(identification: dro.identification.to_h.merge(
            catalogLinks: [{ catalog: 'folio', catalogRecordId: 'in111', refresh: true }]
          ))
        end
      end

      before do
        allow(CatalogRepository).to receive(:exists?).and_return(true)
        edit_item_form.update(version_description: 'Fixed the content type',
                              additional_folio_catalog_links_attributes: [{ catalog_record_id: 'in333' }])
      end

      it 'saves it as a Folio catalog link that is not refreshed' do
        edit_item_form.save!(user_name:)

        expect(Sdr::Repository).to have_received(:update) do |cocina_object:, **|
          expect(cocina_object.identification.catalogLinks.map(&:to_h)).to eq(
            [{ catalog: 'folio', catalogRecordId: 'in111', refresh: true },
             { catalog: 'folio', catalogRecordId: 'in333', refresh: false }]
          )
        end
        expect(CatalogRepository).to have_received(:exists?).once
      end
    end

    context 'when the refresh setting is changed' do
      let(:open) { true }
      let(:cocina_object) do
        unembargoed_cocina_object.then do |dro|
          dro.new(identification: dro.identification.to_h.merge(catalogLinks: [
                                                                  { catalog: 'folio', catalogRecordId: 'in111',
                                                                    refresh: false }
                                                                ]))
        end
      end

      before { edit_item_form.update(version_description: 'Fixed the content type', catalog_link_refresh: true) }

      it 'saves the refresh setting on the Folio catalog link' do
        edit_item_form.save!(user_name:)

        expect(Sdr::Repository).to have_received(:update) do |cocina_object:, **|
          expect(cocina_object.identification.catalogLinks.map(&:to_h))
            .to eq([{ catalog: 'folio', catalogRecordId: 'in111', refresh: true }])
        end
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
        create(:content, :mutable, druid: cocina_object.externalIdentifier, lock: cocina_object.lock,
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
                context: { runOCR: true, ocrLanguages: ['English'] })
        expect(Content.exists?(content.id)).to be false
      end
    end

    context 'when accessioning fails with a content' do
      let(:open) { true }
      let(:content) do
        create(:content, :mutable, druid: cocina_object.externalIdentifier, lock: cocina_object.lock,
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
        create(:content, :mutable, druid: cocina_object.externalIdentifier, lock: cocina_object.lock)
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
