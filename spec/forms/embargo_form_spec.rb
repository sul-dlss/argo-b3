# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbargoForm do
  subject(:form) { described_class.build_from_cocina_object(cocina_object) }

  let(:cocina_object) do
    build(:dro_with_metadata, id: 'druid:bc123df4567').new(
      access: {
        embargo: {
          releaseDate: DateTime.parse('2040-06-15T19:00:00Z'),
          view: 'world',
          download: 'world'
        }
      }
    )
  end

  it 'tracks changes to the embargo release date' do
    form.embargo_release_date = '2041-01-31'

    expect(form).to be_changed
    expect(form).to be_valid
  end

  it 'requires an embargo release date' do
    form.embargo_release_date = nil

    expect(form).not_to be_valid
    expect(form.errors[:embargo_release_date]).to include("can't be blank")
  end
end
