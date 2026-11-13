# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditApoForm do
  subject(:edit_apo_form) { described_class.build_from_cocina_object(cocina_object) }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) do
    build(:admin_policy_with_metadata, id: druid).new(
      description: {
        title: [{ value: 'My APO' }],
        note: [{ value: 'An APO note' }],
        purl: 'https://purl.stanford.edu/bc123df4567'
      }
    )
  end

  describe '.build_from_cocina_object' do
    it 'sets the title from the cocina object, without changes' do
      expect(edit_apo_form.title).to eq('My APO')
      expect(edit_apo_form).not_to be_changed
    end
  end

  describe '.permitted_params' do
    it 'does not permit the governing APO, the description, or tags to be set' do
      expect(described_class.permitted_params).not_to include(:apo_druid)
      expect(described_class.permitted_params).not_to include({ description_hash: [] })
      expect(described_class.permitted_params).not_to include({ tags: [] })
    end
  end

  describe 'location' do
    let(:cocina_object) do
      build(:admin_policy_with_metadata, id: druid).new(
        administrative: {
          hasAdminPolicy: 'druid:hv992ry2431',
          hasAgreement: 'druid:hp308wm0436',
          accessTemplate: { view: 'location-based', download: 'location-based', location: 'spec' }
        }
      )
    end

    before { edit_apo_form.version_description = 'Changed the access' }

    context 'when the access is changed to not be location-based' do
      # The location field is disabled, so no location is submitted.
      before { edit_apo_form.update(access_view: 'world', access_download: 'world') }

      it 'clears the location when validated' do
        expect(edit_apo_form).to be_valid
        expect(edit_apo_form.access_location).to be_nil
      end
    end

    context 'when the access remains location-based' do
      before { edit_apo_form.update(access_view: 'stanford') }

      it 'retains the location' do
        expect(edit_apo_form).to be_valid
        expect(edit_apo_form.access_location).to eq('spec')
      end
    end
  end

  describe 'validation' do
    before { edit_apo_form.version_description = 'Changed the agreement' }

    it 'is valid with a title and version description' do
      expect(edit_apo_form).to be_valid
    end

    context 'without a title' do
      before { edit_apo_form.title = '' }

      it 'is not valid' do
        expect(edit_apo_form).not_to be_valid
        expect(edit_apo_form.errors[:title]).to include("can't be blank")
      end
    end
  end

  describe '#save!' do
    let(:user_name) { 'test_user' }
    let(:version_service) { version_service_double(open?: false, openable?: true, closeable?: false, closed?: true) }
    let(:opened_cocina_object) { cocina_object.new(version: 2) }

    before do
      allow(Sdr::VersionService).to receive(:open).and_return(opened_cocina_object)
      allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object }
      allow(Sdr::Repository).to receive(:accession)
      edit_apo_form.version_service = version_service
      edit_apo_form.update(title: 'My new APO', version_description: 'Changed the title')
    end

    it 'opens a version, saves the changed title retaining the rest of the description, and accessions' do
      edit_apo_form.save!(user_name:, accession: true)

      expect(Sdr::VersionService).to have_received(:open)
        .with(druid:, description: 'Changed the title', opening_user_name: user_name)
      expect(Sdr::Repository).to have_received(:update) do |args|
        updated_cocina_object = args[:cocina_object]
        expect(updated_cocina_object.version).to eq(2)
        expect(updated_cocina_object.description.title.first.value).to eq('My new APO')
        expect(updated_cocina_object.description.note.first.value).to eq('An APO note')
        expect(updated_cocina_object.description.purl).to eq('https://purl.stanford.edu/bc123df4567')
      end
      expect(Sdr::Repository).to have_received(:accession)
        .with(cocina_object: having_attributes(version: 2), user_name:, context: {})
    end
  end
end
