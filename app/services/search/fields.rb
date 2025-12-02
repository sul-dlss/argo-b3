# frozen_string_literal: true

module Search
  # Constants for Solr fields
  module Fields
    ACCESS_RIGHTS = 'rights_descriptions_ssimdv'
    APO_DRUID = 'governed_by_ssim'
    APO_TITLE = 'apo_title_ssimdv'
    BARE_APO_DRUID = 'bare_governed_by_ss'
    BARE_COLLECTION_DRUID = 'bare_member_of_collection_ssm'
    BARE_DRUID = 'druid_bare_ssi'
    COLLECTION_DRUIDS = 'member_of_collection_ssim'
    COLLECTION_TITLES = 'collection_title_ssimdv'
    CONTENT_TYPES = 'content_type_ssimdv'
    EARLIEST_ACCESSIONED_DATE = 'accessioned_earliest_dtpsidv'
    ID = 'id'
    IDENTIFIERS = 'identifier_ssim'
    MIMETYPES = 'content_file_mimetypes_ssimdv'
    OBJECT_TYPES = 'objectType_ssimdv'
    OTHER_TAGS = 'exploded_nonproject_tag_ssimdv'
    OTHER_HIERARCHICAL_TAGS = 'hierarchical_other_tag_ssimdv'
    PROJECTS = 'project_tag_ssim'
    PROJECTS_EXPLODED = 'exploded_project_tag_ssimdv'
    PROJECTS_HIERARCHICAL = 'hierarchical_project_tag_ssimdv'
    RELEASED_TO = 'released_to_ssim'
    RELEASED_TO_EARTHWORKS = 'released_to_earthworks_dtpsidv'
    SOURCE_ID = 'source_id_ssi'
    STATUS = 'status_ssi'
    TICKETS = 'ticket_tag_ssim'
    TITLE = 'display_title_ss'
    WORKFLOW_ERRORS = 'wf_error_ssim'
    WPS_HIERARCHICAL_WORKFLOWS = 'wf_hierarchical_wps_ssimdv'
    WPS_WORKFLOWS = 'wf_wps_ssimdv'
  end
end
