# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ManageLicenseAndRightsStatementsForm do
  subject(:form) { described_class.new(params) }

  describe '#job_params' do
    let(:params) do
      {
        copyright: 'Copyright me', copyright_action: 'update',
        license: 'https://creativecommons.org/licenses/by/4.0/legalcode', license_action: 'remove',
        use_and_reproduction_statement: 'Use it', use_and_reproduction_statement_action: 'no_change'
      }
    end

    it 'changes and sets values only as their actions require' do
      expect(form.job_params).to eq(
        change_copyright: true, copyright: 'Copyright me',
        change_license: true, license: nil,
        change_use_and_reproduction_statement: false, use_and_reproduction_statement: nil
      )
    end
  end
end
