# frozen_string_literal: true

# Component for rendering a banner showing the workgroups currently being impersonated.
class ImpersonationBannerComponent < ApplicationComponent
  delegate :impersonating?, :impersonated_groups, to: :Current

  def render?
    impersonating?
  end
end
