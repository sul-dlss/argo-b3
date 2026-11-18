# frozen_string_literal: true

# PROTOTYPE (throwaway, never merge)
module NotificationsPrototypeHelper
  PROTOTYPE_VARIANTS = { 'A' => 'Header link + table', 'B' => 'Header dropdown + feed',
                         'C' => 'Bell icon + grouped by subject, settings tab' }.freeze

  def prototype_variant
    PROTOTYPE_VARIANTS.key?(params[:variant]) ? params[:variant] : 'A'
  end

  def prototype_outcome_label(outcome)
    { error: 'Error', success: 'Done', info: 'Info' }.fetch(outcome)
  end

  def prototype_outcome_icon(outcome)
    { error: 'bi-exclamation-octagon-fill text-danger', success: 'bi-check-circle-fill text-success',
      info: 'bi-info-circle-fill text-primary' }.fetch(outcome)
  end
end
