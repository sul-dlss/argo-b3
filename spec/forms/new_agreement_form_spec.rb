# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewAgreementForm do
  subject(:new_agreement_form) { described_class.new(title:, source_id: 'sul:agreement-1') }

  let(:title) { 'My Agreement' }

  before do
    allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
  end

  describe '.permitted_params' do
    it 'does not permit the content type, governing APO, or access to be set' do
      expect(described_class.permitted_params)
        .not_to include(:content_type, :apo_druid, :access_view, :access_download, :access_location)
    end
  end

  describe 'fixed values' do
    it 'ignores assigned values for the content type, governing APO, and access' do
      new_agreement_form.assign_attributes(content_type: Cocina::Models::ObjectType.book,
                                           apo_druid: 'druid:dd111dd1111', access_view: 'world',
                                           access_download: 'world', access_location: 'spec')

      expect(new_agreement_form).to have_attributes(content_type: Cocina::Models::ObjectType.agreement,
                                                    apo_druid: Settings.ur_apo_druid, access_view: 'dark',
                                                    access_download: 'none', access_location: nil)
    end
  end

  describe 'validation' do
    context 'when the title is blank' do
      let(:title) { '' }

      it 'is invalid' do
        expect(new_agreement_form).not_to be_valid
        expect(new_agreement_form.errors[:title]).to include("can't be blank")
      end
    end
  end

  describe '#create!' do
    let(:registered_cocina_object) { build(:agreement_with_metadata, id: 'druid:xz987wv6543') }

    before do
      allow(Sdr::Repository).to receive(:register).and_return(registered_cocina_object)
    end

    it 'registers a dark agreement governed by the ur APO' do
      new_agreement_form.create!(user_name: 'admin')

      expect(Sdr::Repository).to have_received(:register) do |args|
        request_cocina_object = args[:request_cocina_object]
        expect(request_cocina_object.type).to eq(Cocina::Models::ObjectType.agreement)
        expect(request_cocina_object.administrative.hasAdminPolicy).to eq(Settings.ur_apo_druid.to_s)
        expect(request_cocina_object.access.to_h).to include(view: 'dark', download: 'none')
        expect(request_cocina_object.description.title.first.value).to eq('My Agreement')
        expect(request_cocina_object.identification.sourceId).to eq('sul:agreement-1')
      end
    end
  end
end
