# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemApoDefaultsForm do
  subject(:form) { described_class.build_from_cocina_object(cocina_object) }

  let(:apo_druid) { 'druid:hv992ry2431' }
  let(:cocina_object) do
    build(:dro_with_metadata, id: 'druid:bc123df4567', admin_policy_id: apo_druid).new(access: item_access)
  end
  let(:item_access) do
    { view: 'world', download: 'world', useAndReproductionStatement: 'Use freely.', copyright: 'Copyright me.',
      license: 'https://www.gnu.org/licenses/agpl.txt' }
  end
  let(:apo_cocina_object) do
    build(:admin_policy_with_metadata, id: apo_druid).new(
      administrative: { hasAdminPolicy: 'druid:hv992ry2431', hasAgreement: 'druid:hp308wm0436',
                        accessTemplate: { view: 'location-based', download: 'location-based', location: 'm&m',
                                          license: 'https://creativecommons.org/licenses/by/4.0/legalcode' } }
    )
  end

  before do
    allow(Sdr::Repository).to receive(:find).with(druid: apo_druid).and_return(apo_cocina_object)
  end

  describe '.build_from_cocina_object' do
    it 'applies the APO access and rights defaults, clearing those the APO does not set' do
      expect(form).to have_attributes(access_view: 'location-based', access_download: 'location-based',
                                      access_location: 'm&m', use_and_reproduction_statement: nil, copyright: nil,
                                      license: 'https://creativecommons.org/licenses/by/4.0/legalcode',
                                      overwrite_file_access: false)
      expect(form).to be_changed
    end

    context 'with an embargo' do
      let(:item_access) do
        { view: 'stanford', download: 'stanford',
          embargo: { releaseDate: '2030-01-01T00:00:00Z', view: 'world', download: 'world' } }
      end

      it 'applies the access defaults during and after the embargo, keeping the release date' do
        expect(form).to have_attributes(access_view: 'location-based', access_location: 'm&m',
                                        embargo_view: 'location-based', embargo_download: 'location-based',
                                        embargo_location: 'm&m',
                                        embargo_release_date: Time.zone.parse('2030-01-01'))
      end
    end
  end

  describe '#save!' do
    let(:content) { create(:content, :mutable, druid: cocina_object.externalIdentifier, lock: cocina_object.lock) }
    let!(:content_file) { create(:content_file, content_file_set: create(:content_file_set, content:)) }

    before do
      allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object.new(lock: 'updated-lock') }
      form.version_service = version_service_double
      form.content = content
      form.version_description = 'Apply APO defaults'
    end

    it 'saves the defaults without changing the file access' do
      form.save!(user_name: 'jlittman')

      expect(Sdr::Repository).to have_received(:update).with(
        cocina_object: an_object_having_attributes(
          access: an_object_having_attributes(view: 'location-based', download: 'location-based', location: 'm&m',
                                              useAndReproductionStatement: nil, copyright: nil,
                                              license: 'https://creativecommons.org/licenses/by/4.0/legalcode')
        ),
        user_name: 'jlittman', description: nil
      )
      expect(content_file.reload).to have_attributes(view: 'world', download: 'world')
    end

    context 'when overwriting file access' do
      before { form.update(overwrite_file_access: true) }

      it 'applies the access to the files' do
        form.save!(user_name: 'jlittman')

        expect(content_file.reload).to have_attributes(view: 'location-based', download: 'location-based',
                                                       location: 'm&m')
      end
    end
  end
end
