# frozen_string_literal: true

module Reports
  # Configurations for report fields
  module Fields # rubocop:disable Metrics/ModuleLength
    def self.find_config_by_field(field)
      Reports::Fields.constants.each do |const_name|
        config = Reports::Fields.const_get(const_name)
        return config if config.is_a?(Config) && config.field == field.to_s
      end
      nil
    end

    Config = Struct.new('Config',
                        :field,
                        :label,
                        :help_text,
                        keyword_init: true)

    ACCESS_RIGHTS = Config.new(
      field: Search::Fields::ACCESS_RIGHTS,
      label: 'Access rights',
      help_text: 'For example: world'
    )

    ACCESSIONED_DATE = Config.new(
      field: Search::Fields::FORMATTED_EARLIEST_ACCESSIONED_DATE,
      label: 'Accessioned date',
      help_text: 'For example: 2020-09-15 08:33:01 PM'
    )

    APO_DRUID = Config.new(
      field: Search::Fields::BARE_APO_DRUID,
      label: 'Admin policy ID',
      help_text: 'For example: bf569gy6501'
    )

    APO_TITLE = Config.new(
      field: Search::Fields::APO_TITLE,
      label: 'Admin policy',
      help_text: 'For example: Google Books'
    )

    AUTHORS = Config.new(
      field: Search::Fields::AUTHOR,
      label: 'Author',
      help_text: 'For example: Twain, Mark, 1835-1910.'
    )

    BARCODES = Config.new(
      field: Search::Fields::BARCODES,
      label: 'Barcode',
      help_text: 'For example: 36105114203446'
    )

    CATALOG_RECORD_ID = Config.new(
      field: Search::Fields::CATALOG_RECORD_ID,
      label: 'Folio Instance HRID',
      help_text: 'For example: a585119'
    )

    COLLECTION_DRUID = Config.new(
      field: Search::Fields::BARE_COLLECTION_DRUID,
      label: 'Collection ID',
      help_text: 'For example: yh583fk3400'
    )

    COLLLECTION_TITLE = Config.new(
      field: Search::Fields::COLLECTION_TITLES,
      label: 'Collection',
      help_text: 'For example: Google Books'
    )

    CONSTITUENTS_COUNT = Config.new(
      field: Search::Fields::CONSTITUENTS_COUNT,
      label: 'Constituents',
      help_text: 'Count of constituents for virtual objects. For example: 12'
    )

    CONTENT_TYPE = Config.new(
      field: Search::Fields::CONTENT_TYPES,
      label: 'Content type',
      help_text: 'For example: book'
    )

    DISSERTATION_ID = Config.new(
      field: Search::Fields::DISSERTATION_ID,
      label: 'Dissertation ID',
      help_text: 'For example: S1234'
    )

    DOI = Config.new(
      field: Search::Fields::DOI,
      label: 'DOI',
      help_text: 'For example: 10.25740/vf000fp9928'
    )

    DRUID = Config.new(
      field: Search::Fields::BARE_DRUID,
      label: 'Druid',
      help_text: 'For example: pj757vx3102'
    )

    EMBARGO_RELEASE_DATE = Config.new(
      field: Search::Fields::FORMATTED_EMBARGO_RELEASE_DATE,
      label: 'Embargo release date',
      help_text: 'For example: 2025-12-04 04:00:00 PM'
    )

    FILE_COUNT = Config.new(
      field: Search::Fields::FILE_COUNT,
      label: 'Files',
      help_text: 'For example: 42'
    )

    HUMAN_PRESERVED_SIZE = Config.new(
      field: Search::Fields::HUMAN_PRESERVED_SIZE,
      label: 'Preservation size',
      help_text: 'For example: 1.5 GB'
    )

    OBJECT_TYPE = Config.new(
      field: Search::Fields::OBJECT_TYPES,
      label: 'Object type',
      help_text: 'For example: item'
    )

    PRESERVATION_SIZE = Config.new(
      field: Search::Fields::PRESERVATION_SIZE,
      label: 'Preservation size (bytes)',
      help_text: 'For example: 1610612736'
    )

    PUBLICATION_CREATED_DATE = Config.new(
      field: Search::Fields::PUBLICATION_CREATED_DATE,
      label: 'Created date',
      help_text: 'For example: 2012'
    )

    PUBLICATION_PLACE = Config.new(
      field: Search::Fields::PUBLICATION_PLACE,
      label: 'Place of publication',
      help_text: 'For example: New York (State)'
    )

    PROCESSING_STATUS = Config.new(
      field: Search::Fields::PROCESSING_STATUS,
      label: 'Processing status',
      help_text: 'For example: Accessioned'
    )

    PROJECT = Config.new(
      field: Search::Fields::PROJECTS,
      label: 'Project',
      help_text: 'For example: Google Books'
    )

    PUBLISHED_DATE = Config.new(
      field: Search::Fields::FORMATTED_PUBLISHED_EARLIEST_DATE,
      label: 'Published date',
      help_text: 'For example: 2020-09-15 08:31:34 PM'
    )

    PUBLISHER = Config.new(
      field: Search::Fields::PUBLISHER,
      label: 'Publisher',
      help_text: 'For example: Harper & Brothers'
    )

    PURL = Config.new(
      field: Search::Fields::PURL,
      label: 'PURL',
      help_text: 'For example: https://purl.stanford.edu/pj757vx3102'
    )

    REGISTERED_BY = Config.new(
      field: Search::Fields::REGISTERED_BY,
      label: 'Registered by',
      help_text: 'For example: dhartwig'
    )

    REGISTERED_DATE = Config.new(
      field: Search::Fields::FORMATTED_REGISTERED_EARLIEST_DATE,
      label: 'Registered date',
      help_text: 'For example: 2020-09-15 08:31:27 PM'
    )

    RELEASED_TO = Config.new(
      field: Search::Fields::RELEASED_TO,
      label: 'Released to',
      help_text: 'For example: Searchworks'
    )

    RESOURCE_COUNT = Config.new(
      field: Search::Fields::RESOURCE_COUNT,
      label: 'Resources',
      help_text: 'For example: 5'
    )

    SHELVED_FILE_COUNT = Config.new(
      field: Search::Fields::SHELVED_FILE_COUNT,
      label: 'Shelved files',
      help_text: 'For example: 15'
    )

    SOURCE_ID = Config.new(
      field: Search::Fields::SOURCE_ID,
      label: 'Source ID',
      help_text: 'For example: googlebooks:stanford_36105114203446'
    )

    TAGS = Config.new(
      field: Search::Fields::OTHER_TAGS,
      label: 'Tags',
      help_text: 'For example: Process : Content Type : Book (ltr)'
    )

    TICKETS = Config.new(
      field: Search::Fields::TICKETS,
      label: 'Tickets',
      help_text: 'For example: DIGREQ-1234'
    )

    TITLE = Config.new(
      field: Search::Fields::TITLE,
      label: 'Title',
      help_text: 'For example: Mark Twain : his words, wit, and wisdom'
    )

    VERSION = Config.new(
      field: Search::Fields::VERSION,
      label: 'Version',
      help_text: 'For example: 3'
    )

    WORKFLOW_ERRORS = Config.new(
      field: Search::Fields::WORKFLOW_ERRORS,
      label: 'Errors',
      help_text: 'For example: content-metadata-create : Path to object gp312jy2810 not found in root directories'
    )
  end
end
