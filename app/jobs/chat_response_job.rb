class ChatResponseJob < ApplicationJob
  def perform(chat_id:, content:, druid:)
    # chat = Chat.find(chat_id)
    # cocina_object = Sdr::Repository.find(druid:)
    # property = 'title'
    # attachment = ActionDispatch::Http::UploadedFile.new(
    #   tempfile: StringIO.new(cocina_object.description.to_h.slice(property.to_sym).to_json),
    #   type: 'application/json',
    #   filename: 'cocina_description.json'
    # )
    cocina_object = Sdr::Repository.find(druid:)

    chat = CocinaDescriptionEditorAgent.find(
      chat_id,
      original_cocina_description_hash: cocina_object.description.to_h
    )

    response = chat.ask(content)
    message = chat.messages.last
    Rails.logger.info "Broadcasting chunk for message #{message.id}: #{response.content}"

    message.broadcast_append_chunk(response.content)
  end
end
