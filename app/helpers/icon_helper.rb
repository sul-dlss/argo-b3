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

  def remove_icon(**)
    icon(icon_classes: %w[bi bi-x-lg], **)
  end

  def exclude_icon(**)
    icon(icon_classes: %w[bi bi-exclude], **)
  end

  # The expand-icon / collapse-icon classes are hooks that search.scss uses to show
  # whichever of the pair matches the aria-expanded state of the surrounding link.
  def expand_icon(**)
    icon(icon_classes: %w[bi bi-plus expand-icon], **)
  end

  def collapse_icon(**)
    icon(icon_classes: %w[bi bi-dash collapse-icon], **)
  end

  def cloud_upload_icon(**)
    icon(icon_classes: %w[bi bi-cloud-arrow-up-fill], **)
  end
end
