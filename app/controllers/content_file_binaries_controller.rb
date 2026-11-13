# frozen_string_literal: true

# Controller for deleting a file binary of a content
class ContentFileBinariesController < ContentsApplicationController
  # Authorization is coming from the verified content_id token.
  skip_verify_authorized only: %i[destroy]
  before_action :set_content_file_binary_and_content

  def destroy
    # Deleting is disabled while busy (e.g., discovery may be adding files), so this is from a stale page.
    return if refused_while_busy?(@content)

    Contents::ContentFileBinaryDestroyer.call(content_file_binaries: [@content_file_binary])
    flash.now[:toast] = t('edit.content_file_binaries.toasts.deleted')
    render formats: :turbo_stream
  end

  private

  def set_content_file_binary_and_content
    verified_content_id = verify_token(params[:content_id])
    @content_file_binary = ContentFileBinary.includes(:content).find(params.expect(:id))
    return forbidden_access if @content_file_binary.content_id != verified_content_id

    @content = @content_file_binary.content
  end
end
