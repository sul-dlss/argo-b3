class ChatsController < ApplicationController
  skip_verify_authorized
  before_action :set_chat, only: %i[show]
  before_action :set_cocina_object, only: %i[new show]

  def show
    @message = @chat.messages.build
    last_description = @chat.last_description || {}
    @cocina_description_hash = @cocina_object.description.to_h.deep_stringify_keys.merge(last_description)
    @purl_preview = PurlPreviewService.call(cocina_hash: @cocina_object.to_h.merge(description: @cocina_description_hash)).then do |body|
      Nokogiri::HTML(body).css('main').inner_html.html_safe
    end
  end

  def new
    # @chat = Chat.new
    # @purl_preview = PurlPreviewService.call(cocina_hash: @cocina_object.to_h).then do |body|
    #   Nokogiri::HTML(body).css('main').inner_html.html_safe
    # end
    # cocina_description_hash = @cocina_object.description.to_h
    @chat = CocinaDescriptionEditorAgent.create!
    redirect_to object_chat_path(@cocina_object.externalIdentifier, @chat)
  end

  # def create
  #   content = params.dig(:chat, :prompt)
  #   return unless content.present?

  #   message = CocinaDescriptionClassifierAgent.new.ask(content)
  #   field = message.content['field']
  #   raise 'Ooops' if field == 'none' # TODO: handle this more gracefully in the UI

  #   cocina_description_hash = @cocina_object.description.to_h
  #   @chat = CocinaDescriptionEditorAgent.create!(original_cocina_description_hash: cocina_description_hash)

  #   content_with_cocina_description = "#{content}\n\nCocina description JSON: #{cocina_description_hash.slice(field.to_sym).to_json}"

  #   # @chat = Chat.create!(model: params.dig(:chat, :model).presence)
  #   ChatResponseJob.perform_later(chat_id: @chat.id, content: content_with_cocina_description,
  #                                 druid: @cocina_object.externalIdentifier)

  #   redirect_to object_chat_path(@cocina_object.externalIdentifier, @chat), notice: 'Chat was successfully created.'
  # end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end

  def set_cocina_object
    @cocina_object = Sdr::Repository.find(druid: params[:object_druid])
  end
end
