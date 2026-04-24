class ChatsController < ApplicationController
  skip_verify_authorized
  before_action :set_chat, only: %i[show destroy]
  before_action :set_cocina_object, only: %i[new create show]

  def index
    @chats = Chat.order(created_at: :desc)
  end

  def show
    @message = @chat.messages.build
  end

  def new
    @chat = Chat.new
    # @selected_model = params[:model]
    # @chat_models = available_chat_models
  end

  def create
    content = params.dig(:chat, :prompt)
    return unless content.present?

    # attachment = ActionDispatch::Http::UploadedFile.new(
    #       tempfile: StringIO.new(cocina_object.description.to_h.slice(property.to_sym).to_json),
    #       type: 'application/json',
    #       filename: 'cocina_description.json'
    #     )

    message = CocinaDescriptionClassifierAgent.new.ask(content)
    field = message.content['field']
    raise 'Ooops' if field == 'none' # TODO: handle this more gracefully in the UI

    cocina_description_hash = @cocina_object.description.to_h
    @chat = CocinaDescriptionEditorAgent.create!(original_cocina_description_hash: cocina_description_hash)

    content_with_cocina_description = "#{content}\n\nCocina description JSON: #{cocina_description_hash.slice(field.to_sym).to_json}"

    # @chat = Chat.create!(model: params.dig(:chat, :model).presence)
    ChatResponseJob.perform_later(chat_id: @chat.id, content: content_with_cocina_description,
                                  druid: @cocina_object.externalIdentifier)

    redirect_to object_chat_path(@cocina_object.externalIdentifier, @chat), notice: 'Chat was successfully created.'
  end

  def destroy
    @chat.destroy!
    redirect_to chats_path, notice: 'Chat was successfully destroyed.', status: :see_other
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end

  def set_cocina_object
    @cocina_object = Sdr::Repository.find(druid: params[:object_druid])
  end
end
