# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManageFilesHelper do
  describe '#manage_files_label' do
    let(:version_service) { instance_double(Sdr::VersionService, first_version_deposited?: first_version_deposited) }

    context 'when the first version has not been deposited' do
      let(:first_version_deposited) { false }

      it 'is Add files and deposit' do
        expect(helper.manage_files_label(version_service:)).to eq('Add files and deposit')
      end
    end

    context 'when the first version has been deposited' do
      let(:first_version_deposited) { true }

      it 'is Edit files and structure' do
        expect(helper.manage_files_label(version_service:)).to eq('Edit files and structure')
      end
    end
  end
end
