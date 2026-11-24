# frozen_string_literal: true

# Concern for pages that open at the results of a check (e.g., a Multi-Item Deposit's Discovery, or validating
# the Register items form) only when they are shown because the check has just finished.
#
# Checks run in the background, and the page with the results is shown when the wait page's scheduled refresh lands
# on it. Reloading the page, arriving by Previous or Next, or opening it from a list show the same results, and
# should open at the top. So starting a check remembers it in the session, and the first page shown after it
# finishes takes (forgets) it.
module ResultsFocusConcern
  extend ActiveSupport::Concern

  SESSION_KEY = :results_focus
  # Checks started in other tabs, or abandoned before they finished, are also remembered, so only the most recent
  # are kept to bound the size of the session.
  MAX_REMEMBERED = 10

  private

  # @param record [ActiveRecord::Base] the record whose check was started
  def remember_results_focus(record)
    keys = Array(session[SESSION_KEY]) - [results_focus_key(record)]
    session[SESSION_KEY] = (keys + [results_focus_key(record)]).last(MAX_REMEMBERED)
  end

  # @param record [ActiveRecord::Base] the record whose check may have finished
  # @return [Boolean] true if a check was started for the record and not yet taken
  def take_results_focus?(record)
    keys = Array(session[SESSION_KEY])
    return false unless keys.include?(results_focus_key(record))

    session[SESSION_KEY] = keys - [results_focus_key(record)]
    true
  end

  def results_focus_key(record)
    "#{record.model_name.param_key}_#{record.id}"
  end
end
