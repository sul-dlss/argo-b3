# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VirtualObjectCsv::Export do
  let(:cocina_object) do
    build(:dro, id: 'druid:bc123df4567', type: Cocina::Models::ObjectType.image)
      .new(structural: { hasMemberOrders: [{ members: ['druid:cd234fg5678', 'druid:df345gh6789'] }] })
  end

  describe '.as_csv' do
    subject(:csv) { described_class.as_csv(cocina_object:) }

    it 'returns a single row of the virtual object druid followed by its constituent druids' do
      expect(csv).to eq("bc123df4567,cd234fg5678,df345gh6789\n")
    end

    it 'is accepted by the create virtual object bulk action' do
      tempfile = Tempfile.new(['virtual_object', '.csv']).tap { |file| file.write(csv) && file.flush }
      form = BulkActions::CreateVirtualObjectForm.new(csv_file: Rack::Test::UploadedFile.new(tempfile.path, 'text/csv'))

      expect(form.valid?).to be true
      expect(form.normalized_csv_file).to eq("druid:bc123df4567,druid:cd234fg5678,druid:df345gh6789\n")
    end
  end
end
