# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MountPathValidator do
  let(:validatable_class) do
    Class.new do
      include ActiveModel::Validations

      attr_accessor :path

      validates :path, mount_path: true

      def self.name
        'ValidatableForMountPath'
      end
    end
  end
  let(:record) { validatable_class.new.tap { |validatable| validatable.path = path } }
  let(:mount_directory) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }
  let(:path) { mount_directory }

  after do
    FileUtils.rm_rf(mount_directory)
  end

  it 'is valid when the path is within a mount location' do
    expect(record).to be_valid
  end

  context 'when the path is blank' do
    let(:path) { '' }

    it 'is valid, leaving presence to a presence validation' do
      expect(record).to be_valid
    end
  end

  context 'when the path does not exist' do
    let(:path) { File.join(mount_directory, 'missing') }

    it 'is not valid' do
      expect(record).not_to be_valid
      expect(record.errors[:path]).to eq(['does not exist'])
    end
  end

  context 'when the path is a mount location' do
    let(:path) { Rails.root.join('tmp').to_s }

    it 'is not valid' do
      expect(record).not_to be_valid
      expect(record.errors[:path]).to eq(['must be within a mount location'])
    end
  end

  context 'when the path is outside the mount locations' do
    let(:path) { Rails.root.join('app').to_s }

    it 'is not valid' do
      expect(record).not_to be_valid
      expect(record.errors[:path]).to eq(['must be within a mount location'])
    end
  end

  context 'when the path traverses outside the mount locations' do
    let(:path) { File.join(mount_directory, '../../app') }

    it 'is not valid' do
      expect(record).not_to be_valid
      expect(record.errors[:path]).to eq(['must be within a mount location'])
    end
  end
end
