# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionApoDefaultsForm do
  subject(:form) { described_class.build_from_cocina_object(cocina_object) }

  let(:apo_druid) { 'druid:hv992ry2431' }
  let(:cocina_object) do
    build(:collection_with_metadata, id: 'druid:bc123df4567', admin_policy_id: apo_druid)
      .new(access: { view: 'world', copyright: 'Copyright me.' })
  end
  let(:apo_cocina_object) do
    build(:admin_policy_with_metadata, id: apo_druid).new(
      administrative: { hasAdminPolicy: 'druid:hv992ry2431', hasAgreement: 'druid:hp308wm0436',
                        accessTemplate: { view: 'dark', download: 'none',
                                          useAndReproductionStatement: 'Ask the library.' } }
    )
  end

  before do
    allow(Sdr::Repository).to receive(:find).with(druid: apo_druid).and_return(apo_cocina_object)
  end

  it 'applies the APO rights defaults without changing the view access' do
    expect(form).to have_attributes(access_view: 'world', use_and_reproduction_statement: 'Ask the library.',
                                    copyright: nil, license: nil)
  end
end
