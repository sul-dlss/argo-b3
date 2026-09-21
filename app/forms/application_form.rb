# frozen_string_literal: true

class ApplicationForm < Voids::Base
  include PermittedParamsConcern
  include NormalizationConcern
end
