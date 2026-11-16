# frozen_string_literal: true

# Presenter for the Redeposit with Goobi button (see GLOSSARY "Goobi Redeposit"): whether it is shown and available.
class GoobiRedepositPresenter
  # @param cocina_object [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] the object
  # @param available [Boolean] true if the user may start a Goobi Redeposit and the object's state allows it
  def initialize(cocina_object:, available:)
    @cocina_object = cocina_object
    @available = available
  end

  # @return [Boolean] true if the button applies to the object (an image or book Item)
  def show?
    Sdr::GoobiRedepositService.goobi_type?(cocina_object)
  end

  # @return [Boolean] true if the button is enabled
  def available?
    @available
  end

  def path
    Rails.application.routes.url_helpers.redeposit_with_goobi_object_path(cocina_object.externalIdentifier)
  end

  private

  attr_reader :cocina_object
end
