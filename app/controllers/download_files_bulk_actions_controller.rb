# frozen_string_literal: true

# Controller for starting a Download files bulk action from an object's Files or Structure tab.
class DownloadFilesBulkActionsController < ApplicationController
  include TokenConcern

  # As with FileDownloadsController, the druid signed by ObjectsController#show acts as authorization;
  # the job checks that the user can read the object.
  skip_verify_authorized only: %i[create]
  self.token_purpose = 'show'

  def create
    druid = verify_token(params.expect(:object_druid))
    bulk_action = BulkAction.create!(action_type: BulkActions::DOWNLOAD_FILES.action_type,
                                     description: "Files for #{druid}", user: current_user)
    bulk_action.enqueue_job(druids: [druid])
  end
end
