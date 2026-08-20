# frozen_string_literal: true

# Helper for rendering icons.
module IconHelper
  include SdrViewComponents::Helpers::IconHelper

  def pin_icon(**)
    icon(icon_classes: %w[bi bi-pin-fill], **)
  end

  def unpin_icon(**)
    icon(icon_classes: %w[bi bi-pin], **)
  end
end
