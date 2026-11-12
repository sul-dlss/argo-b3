# frozen_string_literal: true

# Controller for downloading a file of an object from its staged files, preservation, or stacks.
class FileDownloadsController < ApplicationController
  # Streams the file as it is read, rather than buffering it.
  include ActionController::Live
  include TokenConcern

  # As with the ObjectsController show endpoints, authorization happens on ObjectsController#show.
  # The druid is signed by that action and verified here, which acts as authorization.
  skip_verify_authorized only: %i[show]
  self.token_purpose = 'show'

  def show
    druid = verify_token(params.expect(:object_druid))
    filepath = params.expect(:filepath)
    send_file_headers!(type: 'application/octet-stream', disposition: 'attachment', filename: File.basename(filepath))
    FileDownloadService.stream(druid:, filepath:) { |chunk| response.stream.write(chunk) }
  rescue FileDownloadService::NotFoundError
    redirect_not_available(druid:, filepath:)
  ensure
    response.stream.close
  end

  private

  def redirect_not_available(druid:, filepath:)
    response.headers.delete('Content-Disposition')
    redirect_to object_path(druid), flash: { danger: t('show.errors.file_not_available', filepath:) }
  end
end
