# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptionBuilder do
  subject(:builder) { described_class.new(existing_description: existing) }

  let(:existing) { { title: [{ value: 'Original title' }] } }

  describe '#build' do
    it 'falls back to existing values when submitted fields are all blank' do
      result = builder.build({ title: [{ value: '' }] })
      expect(result[:title]).to eq([{ value: 'Original title' }])
    end

    it 'preserves existing fields not present in submitted params' do
      existing[:note] = [{ value: 'Existing note', type: 'abstract' }]
      result = builder.build({ title: [{ value: 'New title' }] })
      expect(result[:note]).to eq([{ value: 'Existing note', type: 'abstract' }])
    end

    it 'removes nil values from the result' do
      result = builder.build({ title: [{ value: 'A title' }] })
      expect(result).not_to have_key(:note)
    end
  end

  describe 'title building' do
    context 'with a simple value' do
      it 'builds a plain title' do
        result = builder.build({ title: [{ value: 'My Title', type: '' }] })
        expect(result[:title]).to eq([{ value: 'My Title' }])
      end

      it 'includes type when present' do
        result = builder.build({ title: [{ value: 'Alt', type: 'alternative' }] })
        expect(result[:title].first).to eq({ value: 'Alt', type: 'alternative' })
      end

      it 'drops entries with blank value' do
        result = builder.build({ title: [{ value: '' }, { value: 'Real' }] })
        expect(result[:title]).to eq([{ value: 'Real' }])
      end
    end

    context 'with struct_parts' do
      it 'builds a structuredValue title from parts' do
        result = builder.build({
                                 title: [{ struct_parts: [{ value: 'The', type: 'nonsorting characters' },
                                                          { value: 'Great Gatsby', type: 'main title' }],
                                           type: '' }]
                               })
        expect(result[:title].first[:structuredValue]).to eq([
                                                               { value: 'The', type: 'nonsorting characters' },
                                                               { value: 'Great Gatsby', type: 'main title' }
                                                             ])
      end

      it 'sets type on the structured title when present' do
        result = builder.build({
                                 title: [{ struct_parts: [{ value: 'Uniform', type: 'main title' }], type: 'uniform' }]
                               })
        expect(result[:title].first[:type]).to eq('uniform')
      end

      it 'removes type when blank' do
        result = builder.build({
                                 title: [{ struct_parts: [{ value: 'A', type: 'main title' }], type: '' }]
                               })
        expect(result[:title].first).not_to have_key(:type)
      end

      it 'filters out blank parts' do
        result = builder.build({
                                 title: [{ struct_parts: [{ value: '', type: 'main title' },
                                                          { value: 'Real', type: 'main title' }], type: '' }]
                               })
        expect(result[:title].first[:structuredValue]).to eq([{ value: 'Real', type: 'main title' }])
      end

      it 'returns nil (drops the title) when all parts are blank' do
        result = builder.build({
                                 title: [{ struct_parts: [{ value: '', type: '' }], type: '' }]
                               })
        expect(result[:title]).to eq([{ value: 'Original title' }])
      end

      it 'merges _original to preserve unexposed fields' do
        original = { status: 'primary', structuredValue: [] }.to_json
        result = builder.build({
                                 title: [{ struct_parts: [{ value: 'Title', type: 'main title' }],
                                           _original: original, type: '' }]
                               })
        expect(result[:title].first[:status]).to eq('primary')
      end
    end

    context 'with _raw_json' do
      it 'parses and uses the raw JSON directly' do
        raw = { structuredValue: [{ value: 'A', type: 'main title' }] }.to_json
        result = builder.build({ title: [{ _raw_json: raw }] })
        expect(result[:title].first[:structuredValue]).to eq([{ value: 'A', type: 'main title' }])
      end

      it 'drops the title when raw JSON is invalid' do
        result = builder.build({ title: [{ _raw_json: '{invalid' }] })
        expect(result[:title]).to eq([{ value: 'Original title' }])
      end
    end
  end

  describe 'note building' do
    it 'builds a note with value and type' do
      result = builder.build({ note: [{ value: 'An abstract', type: 'abstract' }] })
      expect(result[:note]).to eq([{ value: 'An abstract', type: 'abstract' }])
    end

    it 'drops notes with blank value' do
      result = builder.build({ note: [{ value: '', type: 'abstract' }] })
      expect(result[:note]).to be_nil
    end
  end

  describe 'language building' do
    it 'builds a language entry' do
      result = builder.build({ language: [{ code: 'eng', value: 'English' }] })
      expect(result[:language].first).to eq({ code: 'eng', value: 'English' })
    end

    it 'drops entries with blank code' do
      result = builder.build({ language: [{ code: '', value: 'Unknown' }] })
      expect(result[:language]).to be_nil
    end
  end

  describe 'contributor building' do
    context 'with a simple name' do
      it 'builds a contributor with a plain name value' do
        result = builder.build({
                                 contributor: [{ name_value: 'Smith, Jane', type: 'person', primary: '0' }]
                               })
        expect(result[:contributor].first[:name]).to eq([{ value: 'Smith, Jane' }])
        expect(result[:contributor].first[:type]).to eq('person')
      end

      it 'marks the contributor as primary when checked' do
        result = builder.build({
                                 contributor: [{ name_value: 'Smith, Jane', type: 'person', primary: '1' }]
                               })
        expect(result[:contributor].first[:status]).to eq('primary')
      end

      it 'removes primary status when unchecked' do
        original = { name: [{ value: 'Smith, Jane' }], status: 'primary' }.to_json
        result = builder.build({
                                 contributor: [{ name_value: 'Smith, Jane', type: 'person', primary: '0',
                                                 _original: original }]
                               })
        expect(result[:contributor].first).not_to have_key(:status)
      end
    end

    context 'with life dates' do
      it 'builds a structuredValue name with life dates' do
        result = builder.build({
                                 contributor: [{ name_value: 'Twain, Mark', life_dates: '1835-1910',
                                                 type: 'person', primary: '0' }]
                               })
        name = result[:contributor].first[:name].first
        expect(name[:structuredValue]).to eq([
                                               { value: 'Twain, Mark', type: 'name' },
                                               { value: '1835-1910', type: 'life dates' }
                                             ])
      end
    end

    context 'with a role' do
      it 'sets the role value' do
        result = builder.build({
                                 contributor: [{ name_value: 'Smith, Jane', type: 'person',
                                                 primary: '0', role_value: 'author' }]
                               })
        expect(result[:contributor].first[:role]).to eq([{ value: 'author' }])
      end

      it 'preserves existing role code/uri from _original' do
        original = { name: [{ value: 'x' }],
                     role: [{ value: 'old', code: 'aut', source: { code: 'marcrelator' } }] }.to_json
        result = builder.build({
                                 contributor: [{ name_value: 'Smith, Jane', type: 'person',
                                                 primary: '0', role_value: 'author', _original: original }]
                               })
        role = result[:contributor].first[:role].first
        expect(role[:value]).to eq('author')
        expect(role[:code]).to eq('aut')
        expect(role[:source]).to eq({ code: 'marcrelator' })
      end
    end

    context 'with _raw_json' do
      it 'uses raw JSON directly' do
        raw = { name: [{ value: 'Complex Corp' }], type: 'organization' }.to_json
        result = builder.build({ contributor: [{ _raw_json: raw }] })
        expect(result[:contributor].first[:type]).to eq('organization')
      end
    end

    it 'drops contributors with blank name' do
      result = builder.build({ contributor: [{ name_value: '', type: 'person' }] })
      expect(result[:contributor]).to be_nil
    end
  end

  describe 'subject building' do
    context 'with a simple value' do
      it 'builds a subject with type and source' do
        result = builder.build({
                                 subject: [{ value: 'History', type: 'topic', source_code: 'lcsh' }]
                               })
        expect(result[:subject].first).to eq({
                                               value: 'History', type: 'topic', source: { code: 'lcsh' }
                                             })
      end

      it 'drops subjects with blank value' do
        result = builder.build({ subject: [{ value: '', type: 'topic' }] })
        expect(result[:subject]).to be_nil
      end
    end

    context 'with struct_parts' do
      it 'builds a compound subject heading' do
        result = builder.build({
                                 subject: [{ struct_parts: [{ value: 'Music', type: 'topic' },
                                                            { value: 'France', type: 'place' }] }]
                               })
        expect(result[:subject].first[:structuredValue]).to eq([
                                                                 { value: 'Music', type: 'topic' },
                                                                 { value: 'France', type: 'place' }
                                                               ])
      end

      it 'merges _struct_original to preserve source and other fields' do
        original = { source: { code: 'lcsh' }, structuredValue: [] }.to_json
        result = builder.build({
                                 subject: [{ struct_parts: [{ value: 'Music', type: 'topic' }],
                                             _struct_original: original }]
                               })
        expect(result[:subject].first[:source]).to eq({ code: 'lcsh' })
      end
    end

    context 'with _raw_json' do
      it 'uses raw JSON directly' do
        raw = { value: 'Coordinates', type: 'map coordinates' }.to_json
        result = builder.build({ subject: [{ _raw_json: raw }] })
        expect(result[:subject].first[:type]).to eq('map coordinates')
      end
    end
  end

  describe 'form building' do
    it 'builds a form entry with type and source' do
      result = builder.build({
                               form: [{ value: 'text', type: 'resource type', source_code: 'aat' }]
                             })
      expect(result[:form].first).to eq({ value: 'text', type: 'resource type', source: { code: 'aat' } })
    end

    it 'drops form entries with blank value' do
      result = builder.build({ form: [{ value: '', type: 'resource type' }] })
      expect(result[:form]).to be_nil
    end

    it 'uses raw JSON when present' do
      raw = { value: 'score', type: 'notated music' }.to_json
      result = builder.build({ form: [{ _raw_json: raw }] })
      expect(result[:form].first).to eq({ value: 'score', type: 'notated music' })
    end
  end

  describe 'event building' do
    context 'with a single date' do
      it 'builds an event with type and date' do
        result = builder.build({
                                 event: [{ type: 'publication', date_value: '1978', _original: '{}' }]
                               })
        expect(result[:event].first[:type]).to eq('publication')
        expect(result[:event].first[:date]).to eq([{ value: '1978' }])
      end

      it 'preserves date encoding from _original' do
        original = { date: [{ value: '1978', encoding: { code: 'marc' } }] }.to_json
        result = builder.build({
                                 event: [{ type: 'publication', date_value: '1979', _original: original }]
                               })
        expect(result[:event].first[:date].first).to eq({
                                                          value: '1979', encoding: { code: 'marc' }
                                                        })
      end
    end

    context 'with a date range' do
      it 'builds a structuredValue date with start and end' do
        result = builder.build({
                                 event: [{ type: 'creation', date_start_value: '1920', date_end_value: '1925',
                                           _original: '{}' }]
                               })
        expect(result[:event].first[:date].first[:structuredValue]).to eq([
                                                                            { value: '1920', type: 'start' },
                                                                            { value: '1925', type: 'end' }
                                                                          ])
      end

      it 'omits end when blank' do
        result = builder.build({
                                 event: [{ type: 'creation', date_start_value: '1920', date_end_value: '',
                                           _original: '{}' }]
                               })
        structured = result[:event].first[:date].first[:structuredValue]
        expect(structured).to eq([{ value: '1920', type: 'start' }])
      end
    end

    context 'with a publisher' do
      it 'builds a contributor with publisher role' do
        result = builder.build({
                                 event: [{ type: 'publication', date_value: '1978',
                                           publisher_value: 'Acme Press', _original: '{}' }]
                               })
        contributor = result[:event].first[:contributor].first
        expect(contributor[:name].first[:value]).to eq('Acme Press')
        expect(contributor[:role]).to eq([{ value: 'publisher' }])
        expect(contributor[:type]).to eq('organization')
      end

      it 'preserves publisher role codes from _original' do
        original = {
          contributor: [{ type: 'organization',
                          name: [{ value: 'Old Press' }],
                          role: [{ value: 'publisher', code: 'pbl',
                                   source: { code: 'marcrelator' } }] }]
        }.to_json
        result = builder.build({
                                 event: [{ type: 'publication', date_value: '1978',
                                           publisher_value: 'New Press', _original: original }]
                               })
        role = result[:event].first[:contributor].first[:role].first
        expect(role[:value]).to eq('publisher')
        expect(role[:code]).to eq('pbl')
      end
    end

    context 'with a place' do
      it 'sets the location value' do
        result = builder.build({
                                 event: [{ type: 'publication', date_value: '1978',
                                           place_value: 'New York', _original: '{}' }]
                               })
        expect(result[:event].first[:location].first[:value]).to eq('New York')
      end

      it 'preserves a MARC country code alongside the text location' do
        original = {
          location: [{ code: 'nyu', source: { code: 'marccountry' } },
                     { value: 'New York' }]
        }.to_json
        result = builder.build({
                                 event: [{ type: 'publication', date_value: '1978',
                                           place_value: 'New York (State)', _original: original }]
                               })
        locs = result[:event].first[:location]
        expect(locs.first[:code]).to eq('nyu')
        expect(locs.last[:value]).to eq('New York (State)')
      end
    end

    it 'drops events with blank type and date' do
      result = builder.build({ event: [{ type: '', date_value: '', _original: '{}' }] })
      expect(result[:event]).to be_nil
    end

    it 'uses raw JSON when present' do
      raw = { type: 'broadcast', parallelEvent: [] }.to_json
      result = builder.build({ event: [{ _raw_json: raw }] })
      expect(result[:event].first[:type]).to eq('broadcast')
    end
  end

  describe 'related_resource building' do
    it 'builds a related resource with title and url' do
      result = builder.build({
                               related_resource: [{ title_value: 'Finding Aid', type: 'described by',
                                                    url: 'https://example.com/fa' }]
                             })
      rr = result[:relatedResource].first
      expect(rr[:title]).to eq([{ value: 'Finding Aid' }])
      expect(rr[:access]).to eq({ url: [{ value: 'https://example.com/fa' }] })
      expect(rr[:type]).to eq('described by')
    end

    it 'drops entries with blank title and url' do
      result = builder.build({ related_resource: [{ title_value: '', url: '' }] })
      expect(result[:relatedResource]).to be_nil
    end

    it 'uses raw JSON when present' do
      raw = { type: 'part of', title: [{ value: 'Series' }] }.to_json
      result = builder.build({ related_resource: [{ _raw_json: raw }] })
      expect(result[:relatedResource].first[:type]).to eq('part of')
    end
  end

  describe 'access building' do
    let(:existing) do
      { title: [{ value: 'T' }],
        access: { note: [{ value: 'Existing note', type: 'access restriction' }] } }
    end

    it 'builds physical locations and access contacts' do
      result = builder.build({
                               access: {
                                 physical_location: [{ value: 'PC0139', type: 'shelf locator' }],
                                 access_contact: [{ value: 'spec@stanford.edu', type: 'email' }]
                               }
                             })
      expect(result[:access][:physicalLocation]).to eq([{ value: 'PC0139', type: 'shelf locator' }])
      expect(result[:access][:accessContact]).to eq([{ value: 'spec@stanford.edu', type: 'email' }])
    end

    it 'preserves existing access fields not in the form (e.g. note)' do
      result = builder.build({
                               access: { physical_location: [{ value: 'PC0139', type: 'shelf locator' }],
                                         access_contact: [] }
                             })
      expect(result[:access][:note]).to eq([{ value: 'Existing note', type: 'access restriction' }])
    end

    it 'falls back to existing access when submitted access is blank' do
      result = builder.build({ access: { physical_location: [], access_contact: [] } })
      expect(result[:access]).to eq(existing[:access])
    end

    it 'drops blank entries' do
      result = builder.build({
                               access: {
                                 physical_location: [{ value: '', type: 'shelf locator' }],
                                 access_contact: [{ value: '', type: 'email' }]
                               }
                             })
      expect(result[:access]).to eq(existing[:access])
    end
  end
end
