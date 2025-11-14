# frozen_string_literal: true

# Helper for creating links
module LinkHelper
  def link_to_new_tab(*, data: {}, **, &)
    link_to(*, target: '_blank', rel: 'noopener', data:, **, &)
  end
end
