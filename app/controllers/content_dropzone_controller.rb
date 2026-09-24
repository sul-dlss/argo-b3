# frozen_string_literal: true

# Controller for managing dropzone content
class ContentDropzoneController < ContentsApplicationController
  skip_verify_authorized only: %i[update]

  def update
    verified_content_id = verify_token(params[:content_id])
    content = Content.find(verified_content_id)
    build_content_file_binaries(content:)

    head :ok
  end

  private

  def build_content_file_binaries(content:)
    Contents::BinaryBuilder.call(content:, files: params[:content][:files], paths: params[:content][:paths])
  end
end
