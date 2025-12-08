# frozen_string_literal: true

ACCESSIONWF_TEMPLATE =
  {
    'processes' => [
      { 'label' => 'Start Accessioning', 'name' => 'start-accession' },
      { 'label' => 'Copies files (when present) from staging', 'name' => 'stage' },
      { 'label' => 'Creates the technical metadata by callng technical-metadata-service',
        'name' => 'technical-metadata' },
      { 'label' => 'Shelve content in Digital Stacks', 'name' => 'shelve' },
      { 'label' => 'Sends metadata to PURL (but it may be updated by releaseWF)', 'name' => 'publish' },
      { 'label' => 'Initiate releaseWF', 'name' => 'release-initiate' },
      { 'label' => 'Update DOI Metadata', 'name' => 'update-doi' },
      { 'label' => 'Update ORCID work', 'name' => 'update-orcid-work' },
      { 'label' => 'Initiate Ingest into Preservation', 'name' => 'sdr-ingest-transfer' },
      { 'label' => 'Signal from SDR that object has been received', 'name' => 'sdr-ingest-received' },
      { 'label' => 'Reset workspace by renaming the druid-tree to a versioned directory',
        'name' => 'reset-workspace' },
      { 'label' => 'Start text extraction workflows as needed', 'name' => 'end-accession' }
    ]
  }.freeze
