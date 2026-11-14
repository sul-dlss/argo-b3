# frozen_string_literal: true

# Controller for downloading a file of an object from its staged files, preservation, or stacks.
class FileDownloadsController < ApplicationController
  include TokenConcern

  # As with the ObjectsController show endpoints, authorization happens on ObjectsController#show.
  # The druid is signed by that action and verified here, which acts as authorization.
  skip_verify_authorized only: %i[show]
  self.token_purpose = 'show'

  # Streams the file as a Rack body rather than with ActionController::Live, which drops Content-Length.
  # With Content-Length, the browser fails a download cut short (e.g., by a timeout) rather than saving it as complete.
  def show
    druid = verify_token(params.expect(:object_druid))
    filepath = params.expect(:filepath)
    file_download = FileDownloadService.new(druid:, filepath:)
    send_file_headers!(type: 'application/octet-stream', disposition: 'attachment', filename: File.basename(filepath))
    response.headers.merge!(file_download.headers)
    self.response_body = file_download
  end
end
