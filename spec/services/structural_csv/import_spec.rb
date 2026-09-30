# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructuralCsv::Import do
  subject(:result) { described_class.call(cocina_object:, csv_rows:, line_numbers:) }

  let(:druid) { 'druid:qr773tm1060' }
  let(:bare_druid) { 'qr773tm1060' }
  let(:xlsx_filename) { 'CCTV新闻联播文本数据-20060615-20220630-Stanford University.xlsx' }
  let(:headers) do
    'druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,' \
      'rights_download,rights_location,mimetype,role,file_language,sdr_generated_text,corrected_for_accessibility'
  end
  let(:csv_rows) { CSV.parse(csv, headers: true) }
  let(:line_numbers) { nil }

  let(:cocina_object) do
    build(:dro, id: druid, type: Cocina::Models::ObjectType.image)
      .new(structural:, access: { view: 'world', download: 'world' })
  end

  let(:structural) do
    {
      contains: [
        {
          type: Cocina::Models::FileSetType.image,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23',
          label: 'Image 1',
          version: 1,
          structural: {
            contains: [
              build_file(external_identifier: 'https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd',
                         filename: 'bb045jk9908_0001.tiff', mime_type: 'image/tiff', sdr_preserve: true,
                         publish: false, shelve: false),
              build_file(external_identifier: 'https://cocina.sul.stanford.edu/file/92db9253-19b7-4092-b472-6e73f3c2251e',
                         filename: 'bb045jk9908_0001.jp2', mime_type: 'image/jp2', sdr_preserve: false,
                         publish: true, shelve: true,
                         access: { view: 'location-based', download: 'location-based', location: 'music' })
            ]
          }
        },
        {
          type: Cocina::Models::FileSetType.image,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/a45774e4-ac26-425a-b40e-f5e247135843',
          label: 'Image 2',
          version: 1,
          structural: {
            contains: [
              build_file(external_identifier: 'https://cocina.sul.stanford.edu/file/86de37bc-b930-49ac-936b-15e8db7af88e',
                         filename: 'bb045jk9908_0002.tiff', mime_type: 'image/tiff', sdr_preserve: true,
                         publish: false, shelve: false, language_tag: 'it-IT'),
              build_file(external_identifier: 'https://cocina.sul.stanford.edu/file/55d78b7f-b043-4880-8542-b85f2c3b0414',
                         filename: xlsx_filename, mime_type: 'image/jp2', sdr_preserve: false,
                         publish: true, shelve: true)
            ]
          }
        }
      ]
    }
  end

  def build_file(external_identifier:, filename:, mime_type:, sdr_preserve:, publish:, shelve:, # rubocop:disable Metrics/ParameterLists
                 access: { view: 'world', download: 'world' }, language_tag: nil)
    {
      type: Cocina::Models::ObjectType.file,
      externalIdentifier: external_identifier,
      label: filename,
      filename:,
      size: 4_379_498,
      version: 1,
      hasMimeType: mime_type,
      languageTag: language_tag,
      hasMessageDigests: [
        { type: 'sha1', digest: '9fafbab8986cea0c70bb0aacc9ce282482cad22e' },
        { type: 'md5', digest: '1633661828d894cdaa79f5549f0cd025' }
      ],
      access:,
      administrative: { publish:, sdrPreserve: sdr_preserve, shelve: },
      presentation: { height: 5833, width: 4001 }
    }.compact
  end

  context 'with valid csv that has file properties changed' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Image 1,image,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,stanford,,image/one,,en-US
        #{bare_druid},Image 1,image,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/two,transcription,
        #{bare_druid},Image 2,image,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,none,,image/three,,
        #{bare_druid},Image 2,image,2,#{xlsx_filename},,yes,yes,no,location-based,location-based,music,image/four,,,true,true
      CSV
    end

    let(:new_files) { result.value!.contains.flat_map { |file_set| file_set.structural.contains } }

    it 'updates the files' do
      expect(new_files.map do |file|
        [file.administrative.publish, file.administrative.shelve, file.administrative.sdrPreserve]
      end).to eq [[true, true, true], [true, true, false], [true, true, true], [true, true, false]]
      expect(new_files.map(&:hasMimeType)).to eq ['image/one', 'image/two', 'image/three', 'image/four']
      expect(new_files.map { |file| [file.access.view, file.access.download, file.access.location] }).to eq [
        ['stanford', 'stanford', nil], ['world', 'world', nil], ['stanford', 'none', nil],
        %w[location-based location-based music]
      ]
      expect(new_files.map(&:use)).to eq [nil, 'transcription', nil, nil]
      expect(new_files.map(&:languageTag)).to eq ['en-US', nil, nil, nil]
      expect(new_files.map(&:filename))
        .to eq ['bb045jk9908_0001.tiff', 'bb045jk9908_0001.jp2', 'bb045jk9908_0002.tiff', xlsx_filename]
      expect(new_files.map(&:label))
        .to eq ['bb045jk9908_0001.tiff', 'bb045jk9908_0001.jp2', 'bb045jk9908_0002.tiff', '']
      expect(new_files.map(&:sdrGeneratedText)).to eq [false, false, false, true]
      expect(new_files.map(&:correctedForAccessibility)).to eq [false, false, false, true]
    end

    it 'produces valid cocina' do
      expect { cocina_object.new(structural: result.value!) }.not_to raise_error
    end
  end

  context 'with valid csv that has file set properties changed' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},,page,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},,page,2,#{xlsx_filename},#{xlsx_filename},yes,yes,no,world,world,,image/jp2,
      CSV
    end

    it 'updates the file sets' do
      new_file_sets = result.value!.contains
      expect(new_file_sets.map(&:type)).to eq [Cocina::Models::FileSetType.object, Cocina::Models::FileSetType.page]
      expect(new_file_sets.map(&:label)).to eq ['Picture 1', '']
      expect(new_file_sets.map(&:externalIdentifier))
        .to eq(cocina_object.structural.contains.map(&:externalIdentifier))
    end

    it 'produces valid cocina' do
      expect { cocina_object.new(structural: result.value!) }.not_to raise_error
    end
  end

  context 'with valid csv that adds file sets' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},Picture 2,object,2,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Picture 3,page,3,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},Picture 4,page,4,#{xlsx_filename},#{xlsx_filename},yes,yes,no,world,world,,image/jp2,
      CSV
    end

    it 'adds the file sets' do
      new_file_sets = result.value!.contains
      expect(new_file_sets.map(&:label)).to eq ['Picture 1', 'Picture 2', 'Picture 3', 'Picture 4']
      expect(new_file_sets.map(&:type)).to eq [
        Cocina::Models::FileSetType.object, Cocina::Models::FileSetType.object,
        Cocina::Models::FileSetType.page, Cocina::Models::FileSetType.page
      ]
      expect(new_file_sets[2..].map(&:externalIdentifier))
        .to all(match(%r{\Ahttps://cocina.sul.stanford.edu/fileSet/#{bare_druid}-[0-9a-f-]{36}\z}))
    end

    it 'produces valid cocina' do
      expect { cocina_object.new(structural: result.value!) }.not_to raise_error
    end
  end

  context 'with valid csv that combines file sets' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Picture 1,page,1,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},Picture 1,page,1,#{xlsx_filename},#{xlsx_filename},yes,yes,no,world,world,,image/jp2,
      CSV
    end

    it 'combines the file sets' do
      new_file_sets = result.value!.contains
      expect(new_file_sets.map(&:label)).to eq ['Picture 1']
      # The last row for the sequence determines the type.
      expect(new_file_sets.map(&:type)).to eq [Cocina::Models::FileSetType.page]
      expect(new_file_sets.first.structural.contains.size).to eq 4
    end

    it 'produces valid cocina' do
      expect { cocina_object.new(structural: result.value!) }.not_to raise_error
    end
  end

  context 'with csv that removes files' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Image 1,image,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,no,no,yes,world,world,,image/tiff,
      CSV
    end

    it 'removes the files and file sets' do
      new_file_sets = result.value!.contains
      expect(new_file_sets.size).to eq 1
      expect(new_file_sets.first.structural.contains.map(&:filename)).to eq ['bb045jk9908_0001.tiff']
    end
  end

  context 'with csv containing new files and invalid resource types' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Image 1,image,1,bb045jk_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,world,world,,image/tiff,
        #{bare_druid},Image 1,image,1,bb045jk_0001.jp2,bb045jk9908_0001.jp2,yes,yes,yes,world,world,,image/jp2,
        #{bare_druid},Image 2,image,2,bb045jk_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,world,world,,image/tiff,
        #{bare_druid},Image 2,paper,2,bb045jk_0002.jp2,#{xlsx_filename},yes,yes,yes,world,world,,image/jp2,
        #{bare_druid},Image 2,,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,world,world,,image/tiff,
      CSV
    end

    it 'returns errors' do
      expect(result.failure).to eq [
        'On row 2 found bb045jk_0001.tiff, which appears to be a new file',
        'On row 3 found bb045jk_0001.jp2, which appears to be a new file',
        'On row 4 found bb045jk_0002.tiff, which appears to be a new file',
        'On row 5 found "paper", which is not a valid resource type',
        'On row 5 found bb045jk_0002.jp2, which appears to be a new file',
        'On row 6 found "", which is not a valid resource type'
      ]
    end
  end

  context 'with line numbers provided' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Image 1,image,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,world,world,,image/tiff,
        #{bare_druid},Image 1,image,1,bb045jk_0001.jp2,bb045jk9908_0001.jp2,yes,yes,yes,world,world,,image/jp2,
        #{bare_druid},Image 2,paper,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,world,world,,image/tiff,
      CSV
    end
    let(:line_numbers) { [3, 7, 12] }

    it 'returns errors with the provided line numbers' do
      expect(result.failure).to eq [
        'On row 7 found bb045jk_0001.jp2, which appears to be a new file',
        'On row 12 found "paper", which is not a valid resource type'
      ]
    end
  end

  context 'with line numbers that do not match the rows' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Image 1,image,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,world,world,,image/tiff,
      CSV
    end
    let(:line_numbers) { [2, 3] }

    it 'raises' do
      expect { result }.to raise_error(ArgumentError, 'line_numbers must have one entry per row')
    end
  end

  context 'with invalid sequences' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Image 1,image,0,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,world,world,,image/tiff,
        #{bare_druid},Image 1,image,-1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Image 2,image,two,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,world,world,,image/tiff,
        #{bare_druid},Image 2,image,,#{xlsx_filename},#{xlsx_filename},yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Image 2,image,1.5,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,world,world,,image/tiff,
        #{bare_druid},Image 2,image,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,world,world,,image/tiff,
      CSV
    end

    it 'returns errors' do
      expect(result.failure).to eq [
        'On row 2 found "0", which is not a valid sequence (must be a positive integer)',
        'On row 3 found "-1", which is not a valid sequence (must be a positive integer)',
        'On row 4 found "two", which is not a valid sequence (must be a positive integer)',
        'On row 5 found "", which is not a valid sequence (must be a positive integer)',
        'On row 6 found "1.5", which is not a valid sequence (must be a positive integer)'
      ]
    end
  end

  context 'with switching preservation from no to yes for a file' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,none,,image/tiff,
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Picture 2,page,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,none,,image/tiff,
        #{bare_druid},Picture 2,page,2,#{xlsx_filename},#{xlsx_filename},yes,yes,yes,world,world,,image/jp2,
      CSV
    end

    it 'returns errors' do
      expect(result.failure).to eq [
        "On row 5 found #{xlsx_filename}, which changed preserve from no to yes, which is not supported"
      ]
    end
  end

  context 'when setting shelve=yes with publish=no and preserve=no for a file' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Image 1,image,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,no,yes,no,world,world,,image/tiff,
        #{bare_druid},Image 1,image,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Image 2,image,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,no,no,yes,world,world,,image/tiff,
        #{bare_druid},Image 2,image,2,#{xlsx_filename},#{xlsx_filename},yes,yes,no,world,world,,image/jp2,
      CSV
    end

    it 'returns an error' do
      expect(result.failure).to eq [
        'On row 2 found bb045jk9908_0001.tiff, which has shelve=yes with publish=no and preserve=no, ' \
        'which would cause the file to be deleted from all systems'
      ]
    end
  end

  context 'with location-based rights and no location' do
    let(:csv) do
      <<~CSV
        #{headers}
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,none,,image/tiff,
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Picture 2,page,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,none,,image/tiff,
        #{bare_druid},Picture 2,page,2,#{xlsx_filename},#{xlsx_filename},yes,yes,no,location-based,world,,image/jp2,
      CSV
    end

    it 'returns errors' do
      expect(result.failure).to eq [
        "On row 5 found #{xlsx_filename}, which set view or download rights to location-based " \
        'but did not specify a location'
      ]
    end
  end
end
