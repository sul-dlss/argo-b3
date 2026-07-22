# frozen_string_literal: true

# Controller for chats for description editing.
class DescriptionChatsController < ApplicationController
  before_action :set_chat, only: %i[show]
  before_action :set_cocina_object

  def show
    authorize! @cocina_object, with: ObjectPolicy

    @message = @chat.messages.build
    last_description = @chat.last_description || {}
    @original_cocina_description_hash = @cocina_object.description.to_h.deep_stringify_keys
    @cocina_description_hash = @original_cocina_description_hash.merge(last_description)
    @title = CocinaDisplay::CocinaRecord.new({ 'description' => @cocina_description_hash }).display_title
    @purl_preview = PurlPreviewService.call(cocina_hash: @cocina_object.to_h.merge(description: @cocina_description_hash)).then do |body|
      Nokogiri::HTML(body).css('main').inner_html.html_safe
    end
    @system_and_tool_messages = @chat.messages.where(role: %w[system tool]).order(:created_at)
    @spreadsheet_hash = DescriptiveCsv::Export.export(source_id: @cocina_object.identification.sourceId,
                                                      description: @cocina_description_hash)
  end

  def new
    authorize! @cocina_object, with: ObjectPolicy

    @chat = CocinaDescriptionEditorAgent.create!
    redirect_to object_description_chat_path(@cocina_object.externalIdentifier, @chat)
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end

  def set_cocina_object
    @cocina_object = Sdr::Repository.find(druid: params[:object_druid])
  end
end
