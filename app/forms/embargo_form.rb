# frozen_string_literal: true

# Form object for updating the embargo release date on a DRO.
class EmbargoForm < CocinaModels::Dro
  validates :embargo_release_date, presence: true
end
