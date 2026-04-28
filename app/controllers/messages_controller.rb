class MessagesController < ApplicationController
  skip_verify_authorized
  before_action :set_chat

  def create
    content = message_params[:content]
    return if content.blank?

    # ChatResponseJob.perform_later(@chat.id, content)
    ChatResponseJob.perform_later(chat_id: @chat.id, content:, druid: params[:object_druid])

    @druid = params[:object_druid]

    respond_to do |format|
      format.turbo_stream
      # format.html { redirect_to object_chat_path(@druid, @chat) }
    end
  end

  private

  def message_params
    params.expect(message: [:content])
  end

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end
end
