# frozen_string_literal: true

# Concern for a form that applies the governing APO's rights defaults (use and reproduction statement, copyright,
# and license) to an object, clearing any the APO doesn't set. Includers apply any other defaults (e.g., access) in
# apply_apo_defaults, calling super. Include after EditCocinaObjectFormConcern (or ContentDepositFormConcern).
module ApplyApoDefaultsFormConcern
  extend ActiveSupport::Concern
  include PermittedParamsConcern

  # @return [CocinaModels::AdminPolicy] the governing APO, whose defaults are applied
  attr_reader :apo
  # @return [String] the title of the governing APO
  attr_reader :apo_title

  # A Draft keeps its description; otherwise the new version is described as applying the APO defaults.
  def prefill_version_description
    super
    return if version_description.present?

    self.version_description = I18n.t('edit.object_apo_defaults.new.default_version_description')
  end

  private

  # The defaults are applied as changes, so that they are saved even though they are not submitted.
  def assign_from_cocina_object(cocina_object)
    super
    apo_cocina_object = Sdr::Repository.find(druid: apo_druid)
    @apo = CocinaModels::AdminPolicy.build_from_cocina_object(apo_cocina_object)
    @apo_title = CocinaSupport.title(apo_cocina_object)
    apply_apo_defaults
  end

  def apply_apo_defaults
    self.use_and_reproduction_statement = apo.use_and_reproduction_statement.presence
    self.copyright = apo.copyright.presence
    self.license = apo.license.presence
  end

  # Opens a version even when the object already has the defaults, so that applying them is recorded.
  def open_version_on_save? = true
end
