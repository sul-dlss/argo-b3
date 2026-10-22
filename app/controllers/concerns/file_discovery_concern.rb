# frozen_string_literal: true

# Concern for content controllers that discover files on a mount (e.g., a mount path or Globus).
# While discovery is in progress, show renders a spinner that polls; once complete, it redirects to new.
#
# Controllers that include this concern must define two private methods:
# - discovery_frame_name: the name of the turbo frame that the controller's views render in (e.g., 'mount').
# - new_discovery_path(**params): the path to the controller's new action, with the given params.
module FileDiscoveryConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_content
  end

  def show
    if @content.discovery_not_in_progress?
      flash[:toast] = t('edit.contents.discovery.toasts.completed')
      redirect_to new_discovery_path(files_discovered: true)
    else
      render 'contents/discovering', layout: false, locals: {
        frame_name: discovery_frame_name,
        reload_url: url_for(action: :show, content_id: @content_token, only_path: true),
        discovery_started: params[:discovery_started] == 'true' # Triggers a reload of files section.
      }
    end
  end

  private

  def set_content
    @content_token = params[:content_id]
    verified_content_id = verify_token(@content_token)
    @content = Content.find(verified_content_id)
  end
end
