# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTagsForm do
  subject(:release_tags) { described_class.new(release_choice:) }

  describe 'release_choice' do
    context 'when release_to_collection' do
      let(:release_choice) { 'release_to_collection' }

      it 'is valid' do
        expect(release_tags).to be_valid
      end
    end

    context 'when release_to_targets' do
      subject(:release_tags) { described_class.new(release_choice:, searchworks_target: true) }

      let(:release_choice) { 'release_to_targets' }

      it 'is valid' do
        expect(release_tags).to be_valid
      end
    end

    context 'when no_release' do
      let(:release_choice) { 'no_release' }

      it 'is valid' do
        expect(release_tags).to be_valid
      end
    end

    context 'when blank' do
      let(:release_choice) { '' }

      it 'is not valid' do
        expect(release_tags).not_to be_valid
        expect(release_tags.errors[:release_choice]).to include("can't be blank")
      end
    end

    context 'when nil' do
      let(:release_choice) { nil }

      it 'is not valid' do
        expect(release_tags).not_to be_valid
        expect(release_tags.errors[:release_choice]).to include("can't be blank")
      end
    end

    context 'when not a permitted value' do
      let(:release_choice) { 'bogus' }

      it 'is not valid' do
        expect(release_tags).not_to be_valid
        expect(release_tags.errors[:release_choice]).to include('is not included in the list')
      end
    end
  end

  describe 'targets' do
    context 'when release_choice is release_to_targets and no target is selected' do
      let(:release_choice) { 'release_to_targets' }

      it 'is not valid' do
        expect(release_tags).not_to be_valid
        expect(release_tags.errors[:release_targets]).to include('At least one target must be selected')
      end
    end

    context 'when release_choice is release_to_targets and a target is selected' do
      subject(:release_tags) { described_class.new(release_choice:, earthworks_target: true) }

      let(:release_choice) { 'release_to_targets' }

      it 'is valid' do
        expect(release_tags).to be_valid
      end
    end

    context 'when release_choice is not release_to_targets and no target is selected' do
      let(:release_choice) { 'no_release' }

      it 'is valid' do
        expect(release_tags).to be_valid
      end
    end
  end

  describe '#create!' do
    let(:druid) { 'druid:bc123df4567' }
    let(:user_name) { 'jcoyne' }

    before do
      allow(Sdr::Repository).to receive(:create_release_tag)
    end

    context 'when release_choice is invalid' do
      let(:release_choice) { '' }

      it 'raises' do
        expect { release_tags.create!(druid:, user_name:) }.to raise_error(ActiveModel::ValidationError)
      end
    end

    context 'when release_to_collection' do
      let(:release_choice) { 'release_to_collection' }

      it 'does not create a release tag' do
        release_tags.create!(druid:, user_name:)

        expect(Sdr::Repository).not_to have_received(:create_release_tag)
      end
    end

    context 'when no_release' do
      let(:release_choice) { 'no_release' }

      it 'creates a release tag with release false and no target' do
        release_tags.create!(druid:, user_name:)

        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: nil, release: false)
      end
    end

    context 'when release_to_targets' do
      subject(:release_tags) do
        described_class.new(release_choice:, searchworks_target:, earthworks_target:, purl_sitemap_target:)
      end

      let(:release_choice) { 'release_to_targets' }
      let(:searchworks_target) { true }
      let(:earthworks_target) { false }
      let(:purl_sitemap_target) { true }

      it 'creates a release tag for each selected target' do
        release_tags.create!(druid:, user_name:)

        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Searchworks', release: true)
        expect(Sdr::Repository).to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'PURL sitemap', release: true)
        expect(Sdr::Repository).not_to have_received(:create_release_tag)
          .with(druid:, user_name:, release_target: 'Earthworks', release: true)
      end
    end
  end
end
