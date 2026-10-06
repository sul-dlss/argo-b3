# frozen_string_literal: true

# Controller for showing the technical metadata for a file of an object.
class TechnicalMetadataController < ApplicationController
  include TokenConcern

  # As with the ObjectsController show endpoints, authorization happens on ObjectsController#show.
  # The druid is signed by that action and verified here, which acts as authorization.
  skip_verify_authorized only: %i[show]
  self.token_purpose = 'show'

  def show
    druid = verify_token(params.expect(:object_druid))
    filepath = params.expect(:filepath)
    begin
      @technical_metadata = Sdr::TechnicalMetadata.find(druid:, filepath:)
    rescue Sdr::TechnicalMetadata::Error => e
      Honeybadger.notify(e, context: { druid:, filepath: })
      @technical_metadata = nil
    end

    render layout: false
  end
end
