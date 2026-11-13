# frozen_string_literal: true

# Concern for content controllers that discover files on a mount (e.g., a mount path or Globus).
module FileDiscoveryConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_content
  end

  private

  def set_content
    @content_token = params[:content_id]
    verified_content_id = verify_token(@content_token)
    @content = Content.find(verified_content_id)
  end

  # Refreshes the page, which then shows that files are being discovered (see ContentsController#edit).
  # Nothing is started while the content is busy, e.g., from another tab while structuring.
  # @param job_args [Hash] additional keyword arguments for DiscoverFilesJob#perform
  def start_discovery(**job_args)
    unless @content.busy?
      @content.discovery_started!
      DiscoverFilesJob.perform_later(content: @content, **job_args)
    end
    render_page_refresh
  end
end
