# frozen_string_literal: true

# Helper for creating links
module LinkHelper
  def link_to_new_tab(*, data: {}, **, &)
    link_to(*, target: '_blank', rel: 'noopener', data:, **, &)
  end

  def link_to_item(label, druid, *, data: {}, **, &)
    link_to_new_tab(label, "#{Settings.argo.url}/view/#{druid}", *, data:, **, &)
  end
end
