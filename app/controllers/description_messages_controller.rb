# frozen_string_literal: true

# Controller for messages in a chat for description editing.
class DescriptionMessagesController < ApplicationController
  def create
    @druid = params[:object_druid]

    cocina_object = Sdr::Repository.find(druid: @druid)
    authorize! cocina_object, with: ObjectPolicy

    content = message_params[:content]
    return head :unprocessable_content if content.blank?

    chat_id = params[:description_chat_id] || params[:chat_id]
    ChatResponseJob.perform_later(chat_id:, content:, druid: @druid)
  end

  private

  def message_params
    params.expect(message: [:content])
  end
end
