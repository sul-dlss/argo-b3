# frozen_string_literal: true

# Concern for collection forms whose governing APO must be one of the APOs the user may select.
module SelectableApoFormConcern
  extend ActiveSupport::Concern

  included do
    # The druids of the APOs the user may select, set by the controller. Permissions do not
    # distinguish APOs from collections, so this ensures that the governing APO is an APO.
    # Not an attribute, so that it is not a param.
    # @return [Array<String>, nil] nil to skip the check
    attr_accessor :selectable_apo_druids

    validate :apo_druid_must_be_selectable, if: -> { selectable_apo_druids && apo_druid.present? }
  end

  private

  def apo_druid_must_be_selectable
    return if selectable_apo_druids.include?(apo_druid)

    errors.add(:apo_druid, I18n.t('edit.collections.fields.apo_druid.validations.not_selectable'))
  end
end
