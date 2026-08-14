# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Builder do
  subject(:content) { described_class.call(cocina_object:) }

  let(:cocina_object) { Cocina::Models.with_metadata(Cocina::Models.build(JSON.parse(json)), 'abc123') }

  let(:druid) { 'druid:qr773tm1060' }

  context 'with no file sets' do
    let(:json) do
      <<~JSON
        {
          "type": "#{Cocina::Models::ObjectType.image}",
          "externalIdentifier": "#{druid}",
          "version": 1,
          "access": {
            "view": "world",
            "download": "world"
          },
          "administrative": {
            "hasAdminPolicy": "druid:fh940mz2717"
          },
          "description": {
            "title": [
              {
                "value": "dood"
              }
            ],
            "purl": "https://purl.stanford.edu/qr773tm1060",
            "access": {
              "digitalRepository": [
                {
                  "value": "Stanford Digital Repository"
                }
              ]
            }
          },
          "identification": {
            "sourceId": "foo:129"
          },
          "structural": {}
        }
      JSON
    end

    it 'creates a Content with no ContentFileSets' do
      expect(content).to be_a(Content)
      expect(content).to have_attributes(druid:, lock: 'abc123')
      expect(content.content_file_sets).to be_empty
    end
  end

  context 'with file sets and files' do
    let(:json) do
      <<~JSON
        {
          "type": "#{Cocina::Models::ObjectType.image}",
          "externalIdentifier": "#{druid}",
          "version": 1,
          "access": {
            "view": "world",
            "download": "world"
          },
          "administrative": {
            "hasAdminPolicy": "druid:fh940mz2717"
          },
          "description": {
            "title": [
              {
                "value": "dood"
              }
            ],
            "purl": "https://purl.stanford.edu/qr773tm1060",
            "access": {
              "digitalRepository": [
                {
                  "value": "Stanford Digital Repository"
                }
              ]
            }
          },
          "identification": {
            "sourceId": "foo:129"
          },
          "structural": {
            "contains": [
              {
                "type": "#{Cocina::Models::FileSetType.image}",
                "externalIdentifier": "https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23",
                "label": "Image 1",
                "version": 1,
                "structural": {
                  "contains": [
                    {
                      "type": "#{Cocina::Models::ObjectType.file}",
                      "externalIdentifier": "https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd",
                      "label": "Image 1 file",
                      "filename": "folder1/qr773tm1060_0001.tiff",
                      "size": 22454748,
                      "version": 1,
                      "hasMimeType": "image/tiff",
                      "use": "transcription",
                      "languageTag": "en",
                      "sdrGeneratedText": true,
                      "correctedForAccessibility": true,
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "ff66b3b3dc3ef733d39e949549791ff78754871b"
                        },
                        {
                          "type": "md5",
                          "digest": "b6ce12a1dd5db09f10b51659c83f90a3"
                        }
                      ],
                      "access": {
                        "view": "location-based",
                        "download": "location-based",
                        "location": "music"
                      },
                      "administrative": {
                        "publish": true,
                        "sdrPreserve": false,
                        "shelve": true
                      },
                      "presentation": {
                        "height": 5833,
                        "width": 4001
                      }
                    }
                  ]
                }
              },
              {
                "type": "#{Cocina::Models::FileSetType.page}",
                "externalIdentifier": "https://cocina.sul.stanford.edu/fileSet/a45774e4-ac26-425a-b40e-f5e247135843",
                "label": "Page 1",
                "version": 1,
                "structural": {
                  "contains": [
                    {
                      "type": "#{Cocina::Models::ObjectType.file}",
                      "externalIdentifier": "https://cocina.sul.stanford.edu/file/86de37bc-b930-49ac-936b-15e8db7af88e",
                      "label": "Page 1 file",
                      "filename": "qr773tm1060_0002.tiff",
                      "version": 1,
                      "hasMessageDigests": [],
                      "access": {
                        "view": "world",
                        "download": "world"
                      },
                      "administrative": {
                        "publish": false,
                        "sdrPreserve": true,
                        "shelve": false
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      JSON
    end

    it 'creates a Content with ContentFileSets and ContentFiles' do
      expect(content).to have_attributes(druid:, lock: 'abc123')

      file_sets = content.content_file_sets.sort_by(&:position)
      expect(file_sets.size).to eq(2)

      first_file_set = file_sets.first
      expect(first_file_set).to have_attributes(
        file_set_type: 'image',
        label: 'Image 1',
        external_identifier: 'https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23',
        position: 1
      )

      first_file = first_file_set.content_files.sole
      expect(first_file).to have_attributes(
        position: 1,
        file_location: 'deposited',
        label: 'Image 1 file',
        filepath: 'folder1/qr773tm1060_0001.tiff',
        basename: 'qr773tm1060_0001',
        extname: 'tiff',
        path_parts: ['folder1'],
        external_identifier: 'https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd',
        size: 22_454_748,
        mime_type: 'image/tiff',
        md5_digest: 'b6ce12a1dd5db09f10b51659c83f90a3',
        sha1_digest: 'ff66b3b3dc3ef733d39e949549791ff78754871b',
        language_tag: 'en',
        use: 'transcription',
        sdr_generated_text: true,
        corrected_for_accessibility: true,
        view: 'location-based',
        download: 'location-based',
        location: 'music',
        publish: true,
        preserve: false,
        shelve: true,
        height: 5833,
        width: 4001
      )

      second_file_set = file_sets.second
      expect(second_file_set).to have_attributes(file_set_type: 'page', label: 'Page 1', position: 2)

      second_file = second_file_set.content_files.sole
      expect(second_file).to have_attributes(
        position: 1,
        filepath: 'qr773tm1060_0002.tiff',
        mime_type: nil,
        md5_digest: nil,
        sha1_digest: nil,
        language_tag: nil,
        use: nil,
        sdr_generated_text: false,
        corrected_for_accessibility: false,
        view: 'world',
        download: 'world',
        location: nil,
        publish: false,
        preserve: true,
        shelve: false,
        height: nil,
        width: nil
      )
    end
  end

  context 'with multiple files in one file set' do
    let(:json) do
      <<~JSON
        {
          "type": "#{Cocina::Models::ObjectType.image}",
          "externalIdentifier": "#{druid}",
          "version": 1,
          "access": {
            "view": "world",
            "download": "world"
          },
          "administrative": {
            "hasAdminPolicy": "druid:fh940mz2717"
          },
          "description": {
            "title": [
              {
                "value": "dood"
              }
            ],
            "purl": "https://purl.stanford.edu/qr773tm1060",
            "access": {
              "digitalRepository": [
                {
                  "value": "Stanford Digital Repository"
                }
              ]
            }
          },
          "identification": {
            "sourceId": "foo:129"
          },
          "structural": {
            "contains": [
              {
                "type": "#{Cocina::Models::FileSetType.image}",
                "externalIdentifier": "https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23",
                "label": "Image 1",
                "version": 1,
                "structural": {
                  "contains": [
                    {
                      "type": "#{Cocina::Models::ObjectType.file}",
                      "externalIdentifier": "https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd",
                      "label": "Image 1 file",
                      "filename": "qr773tm1060_0001.tiff",
                      "version": 1,
                      "hasMessageDigests": [],
                      "access": {
                        "view": "world",
                        "download": "world"
                      },
                      "administrative": {
                        "publish": true,
                        "sdrPreserve": false,
                        "shelve": true
                      }
                    },
                    {
                      "type": "#{Cocina::Models::ObjectType.file}",
                      "externalIdentifier": "https://cocina.sul.stanford.edu/file/86de37bc-b930-49ac-936b-15e8db7af88e",
                      "label": "Image 2 file",
                      "filename": "qr773tm1060_0002.tiff",
                      "version": 1,
                      "hasMessageDigests": [],
                      "access": {
                        "view": "world",
                        "download": "world"
                      },
                      "administrative": {
                        "publish": true,
                        "sdrPreserve": false,
                        "shelve": true
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      JSON
    end

    it 'assigns contiguous positions to each file within the file set' do
      file_set = content.content_file_sets.sole
      files = file_set.content_files.sort_by(&:position)

      expect(files.map(&:position)).to eq([1, 2])
      expect(files.map(&:filepath)).to eq(['qr773tm1060_0001.tiff', 'qr773tm1060_0002.tiff'])
    end
  end

  context 'with the same filename referenced from multiple file sets' do
    let(:json) do
      <<~JSON
        {
          "type": "#{Cocina::Models::ObjectType.image}",
          "externalIdentifier": "#{druid}",
          "version": 1,
          "access": {
            "view": "world",
            "download": "world"
          },
          "administrative": {
            "hasAdminPolicy": "druid:fh940mz2717"
          },
          "description": {
            "title": [
              {
                "value": "dood"
              }
            ],
            "purl": "https://purl.stanford.edu/qr773tm1060",
            "access": {
              "digitalRepository": [
                {
                  "value": "Stanford Digital Repository"
                }
              ]
            }
          },
          "identification": {
            "sourceId": "foo:129"
          },
          "structural": {
            "contains": [
              {
                "type": "#{Cocina::Models::FileSetType.image}",
                "externalIdentifier": "https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23",
                "label": "Image 1",
                "version": 1,
                "structural": {
                  "contains": [
                    {
                      "type": "#{Cocina::Models::ObjectType.file}",
                      "externalIdentifier": "https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd",
                      "label": "Image 1 file",
                      "filename": "qr773tm1060_0001.tiff",
                      "size": 22454748,
                      "version": 1,
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "ff66b3b3dc3ef733d39e949549791ff78754871b"
                        }
                      ],
                      "access": {
                        "view": "world",
                        "download": "world"
                      },
                      "administrative": {
                        "publish": true,
                        "sdrPreserve": false,
                        "shelve": true
                      }
                    }
                  ]
                }
              },
              {
                "type": "#{Cocina::Models::FileSetType.page}",
                "externalIdentifier": "https://cocina.sul.stanford.edu/fileSet/a45774e4-ac26-425a-b40e-f5e247135843",
                "label": "Page 1",
                "version": 1,
                "structural": {
                  "contains": [
                    {
                      "type": "#{Cocina::Models::ObjectType.file}",
                      "externalIdentifier": "https://cocina.sul.stanford.edu/file/86de37bc-b930-49ac-936b-15e8db7af88e",
                      "label": "Page 1 file",
                      "filename": "qr773tm1060_0001.tiff",
                      "size": 22454748,
                      "version": 1,
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "ff66b3b3dc3ef733d39e949549791ff78754871b"
                        }
                      ],
                      "access": {
                        "view": "world",
                        "download": "world"
                      },
                      "administrative": {
                        "publish": false,
                        "sdrPreserve": true,
                        "shelve": false
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      JSON
    end

    it 'creates a single ContentFileBinary shared by a ContentFile in each file set' do
      expect(content.content_file_binaries.size).to eq(1)

      content_file_binary = content.content_file_binaries.sole
      expect(content_file_binary.filepath).to eq('qr773tm1060_0001.tiff')

      file_sets = content.content_file_sets.sort_by(&:position)
      expect(file_sets.map { |file_set| file_set.content_files.sole.content_file_binary }).to all(
        eq(content_file_binary)
      )
    end
  end
end
