# frozen_string_literal: true

# Helper for creating links
module LinkHelper
  # Links to an object's show page, with Turbo prefetching disabled (since prefetching would
  # record the linked object as recently viewed, which we do not want).
  #
  # @param label [String] the link text
  # @param druid [String] the druid of the object to link to
  # @param data [Hash] Turbo/Stimulus data attributes to merge onto the link
  # @param path_params [Hash] additional querystring params to append to the object's link path (e.g., search_position:)
  # @param options [Hash] any other html attributes to pass to link_to (e.g., rel:, 'aria-label':)
  def link_to_object(label, druid, *, data: {}, **options)
    path_params = options.delete(:path_params) || {}
    link_to(label, object_path(druid:, **path_params), data: data.merge(turbo_prefetch: false), **options)
  end

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
    "#{Settings.searchworks.url}/view/#{catalog_record_id.presence || DruidSupport.bare_druid_from(druid)}"
  end

  def earthworks_url(druid)
    "#{Settings.earthworks.url}/catalog/stanford-#{DruidSupport.bare_druid_from(druid)}"
  end
end
