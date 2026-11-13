# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditCocinaObjectFormConcern do
  let(:form_class) do
    stub_const('TestEditForm', Class.new(CocinaModels::AdminPolicy) do
      include EditCocinaObjectFormConcern
      include LockFormConcern

      attribute :show_help, :boolean, default: false
      form_only_attributes :show_help
    end)
  end

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }
  let(:open) { true }
  let(:version_service) { version_service_double(open?: open, version: 2, version_description: 'Open version') }
  let(:stanford_access) { { access_view: 'stanford', access_download: 'stanford' } }

  describe '.for_edit' do
    subject(:form) { form_class.for_edit(cocina_object, version_service:) }

    it 'prefills the open version description and the lock, without changes' do
      expect(form).to have_attributes(version_description: 'Open version', lock: cocina_object.lock)
      expect(form).not_to be_changed
    end

    context 'when the version is closed' do
      let(:open) { false }

      it 'leaves the version description blank' do
        expect(form.version_description).to be_nil
      end
    end
  end

  describe '.from_submission' do
    subject(:form) { form_class.from_submission(cocina_object, version_service:, params:) }

    let(:params) { stanford_access.merge(version_description: 'Changed the access', lock: cocina_object.lock) }

    it 'applies the submitted changes, and is not stale' do
      expect(form).to have_attributes(access_view: 'stanford', version_description: 'Changed the access')
      expect(form).to be_changed
      expect(form).not_to be_stale
    end

    context 'with another lock' do
      let(:params) { { version_description: 'Changed the access', lock: 'other-lock' } }

      it 'is stale' do
        expect(form).to be_stale
      end
    end

    context 'without a lock' do
      let(:params) { { version_description: 'Changed the access' } }

      it 'is stale' do
        expect(form).to be_stale
      end
    end
  end

  describe '#changed?' do
    subject(:form) { form_class.build_from_cocina_object(cocina_object) }

    it 'is false when only form-only attributes changed' do
      form.update(version_description: 'Changed nothing', lock: 'other-lock', show_help: true)

      expect(form).not_to be_changed
    end

    it 'is true when an attribute of the cocina object changed' do
      form.update(access_view: 'stanford')

      expect(form).to be_changed
    end
  end

  describe 'validation' do
    subject(:form) { form_class.build_from_cocina_object(cocina_object) }

    it 'requires a version description' do
      expect(form).not_to be_valid
      expect(form.errors[:version_description]).to eq(["can't be blank"])
    end
  end

  describe '#save!' do
    subject(:form) { form_class.from_submission(cocina_object, version_service:, params:) }

    let(:user_name) { 'jdoe' }
    let(:params) { stanford_access.merge(version_description: 'Changed the access', lock: cocina_object.lock) }
    let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }

    before do
      allow(Sdr::VersionService).to receive(:open).and_return(opened_cocina_object)
      allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object }
      allow(Sdr::Repository).to receive(:accession)
    end

    context 'when the version is open and the version description changed' do
      it 'updates the version description and saves without opening a version' do
        form.save!(user_name:)

        expect(version_service).to have_received(:update_description).with(description: 'Changed the access',
                                                                           user_name:)
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).to have_received(:update)
          .with(cocina_object: having_attributes(lock: cocina_object.lock), user_name:, description: nil)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when the version is open and the version description did not change' do
      let(:params) { stanford_access.merge(version_description: 'Open version', lock: cocina_object.lock) }

      it 'saves without updating the version description' do
        form.save!(user_name:)

        expect(version_service).not_to have_received(:update_description)
        expect(Sdr::Repository).to have_received(:update)
      end
    end

    context 'when the version is closed and there are changes' do
      let(:open) { false }

      it 'opens a version and saves against it' do
        form.save!(user_name:)

        expect(Sdr::VersionService).to have_received(:open)
          .with(druid:, description: 'Changed the access', opening_user_name: user_name)
        expect(Sdr::Repository).to have_received(:update)
          .with(cocina_object: having_attributes(version: 2, lock: 'opened-lock'), user_name:, description: nil)
      end
    end

    context 'when the version is closed and there are no changes' do
      let(:open) { false }
      let(:params) { { version_description: 'Nothing really', lock: cocina_object.lock } }

      it 'neither opens a version nor saves' do
        form.save!(user_name:)

        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when accessioning with a closed version and no changes' do
      let(:open) { false }
      let(:params) { { version_description: 'Redeposit', lock: cocina_object.lock } }

      it 'opens a version and accessions it without saving' do
        form.save!(user_name:, accession: true)

        expect(Sdr::VersionService).to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: opened_cocina_object, user_name:, context: {})
      end
    end

    context 'without a version description' do
      let(:open) { false }
      let(:params) { stanford_access.merge(lock: cocina_object.lock) }

      it 'raises without opening a version or saving' do
        expect { form.save!(user_name:) }.to raise_error(ActiveModel::ValidationError)
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end
  end
end
