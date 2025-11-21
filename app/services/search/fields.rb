# frozen_string_literal: true

module Search
  # Constants for Solr fields
  module Fields
    ACCESS_RIGHTS = 'rights_descriptions_ssimdv'
    APO_ID = 'governed_by_ssim'
    BARE_DRUID = 'druid_bare_ssi'
    ID = 'id'
    MIMETYPES = 'content_file_mimetypes_ssimdv'
    OBJECT_TYPE = 'objectType_ssimdv'
    OTHER_TAGS = 'exploded_nonproject_tag_ssimdv'
    OTHER_HIERARCHICAL_TAGS = 'hierarchical_other_tag_ssimdv'
    PROJECT_TAGS = 'exploded_project_tag_ssimdv'
    PROJECT_HIERARCHICAL_TAGS = 'hierarchical_project_tag_ssimdv'
    TITLE = 'display_title_ss'
    WPS_HIERARCHICAL_WORKFLOWS = 'wf_hierarchical_wps_ssimdv'
    WPS_WORKFLOWS = 'wf_wps_ssimdv'
  end
end
