# frozen_string_literal: true

# Helper for creating links
module LinkHelper
  def link_to_new_tab(*, data: {}, **, &)
    link_to(*, target: '_blank', rel: 'noopener', data:, **, &)
  end

  def link_to_old_argo(label, druid, *, data: {}, **, &)
    link_to_new_tab(label, "#{Settings.argo.url}/view/#{druid}", *, data:, **, &)
  end

  def link_to_purl(druid, *, data: {}, **, &)
    link_to_new_tab('View PURL page', Cocina::Models::Mapping::Purl.for(druid:), *, data:, **, &)
  end

  def searchworks_url(druid, catalog_record_id = nil)
    "#{Settings.searchworks.url}/view/#{catalog_record_id.presence || druid}"
  end

  def earthworks_url(druid)
    "#{Settings.earthworks.url}/catalog/stanford-#{DruidSupport.bare_druid_from(druid)}"
  end
end
