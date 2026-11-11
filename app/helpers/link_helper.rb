# frozen_string_literal: true

# Helper for creating links
module LinkHelper
  # Links to an object's show page, with Turbo prefetching disabled (since prefetching would
  # record the linked object as recently viewed, which we do not want).
  #
  # @param label [String] the link text
  # @param druid [String] the druid of the object to link to
  # @param data [Hash] Turbo/Stimulus data attributes to merge onto the link
  # @param options [Hash] any other html attributes to pass to link_to (e.g., rel:, 'aria-label':)
  def link_to_object(label, druid, *, data: {}, **)
    link_to(label, object_path(druid:), data: data.merge(turbo_prefetch: false), **)
  end

  # Links to a page outside Argo B3 in a new tab, with the external-link icon and an announcement.
  def link_to_new_tab(label, url, **)
    link_to(new_tab_label(label), url, target: '_blank', rel: 'noopener', **)
  end

  # @return [ActiveSupport::SafeBuffer] the label with the external-link icon and "(opens in new tab)"
  def new_tab_label(label)
    safe_join([label, ' ', external_link_icon(aria: { hidden: true }),
               tag.span(' (opens in new tab)', class: 'visually-hidden')])
  end

  # @return [ActiveSupport::SafeBuffer] the text followed by visually hidden context, e.g., for repeated per-row links
  def text_with_hidden_context(text, context)
    safe_join([text, tag.span(" #{context}", class: 'visually-hidden')])
  end

  def link_to_purl(druid, **)
    link_to_new_tab('View PURL page', Cocina::Models::Mapping::Purl.for(druid:), **)
  end

  def searchworks_url(druid, catalog_record_id = nil)
    "#{Settings.searchworks.url}/view/#{catalog_record_id.presence || DruidSupport.bare_druid_from(druid)}"
  end

  def earthworks_url(druid)
    "#{Settings.earthworks.url}/catalog/stanford-#{DruidSupport.bare_druid_from(druid)}"
  end
end
