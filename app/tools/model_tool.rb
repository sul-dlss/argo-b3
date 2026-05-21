# frozen_string_literal: true

class ModelTool < RubyLLM::Tool
  description 'Gets instructions for models of properties.'

  params do
    string :name, description: 'Name of the model.'
  end

  def execute(name:)
    Rails.logger.info "ModelTool called with name: #{name}"
    unless all_models.include?(name)
      return "No instructions found for model: #{name}. Valid names are: #{all_models.join(', ')}"
    end

    CocinaDescriptionEditorAgent.render_prompt(name.tr(' ', '_'), chat: nil, inputs: {}, locals: {})
  end

  private

  def all_models
    @@all_models ||= Rails.root.glob('app/prompts/cocina_description_editor_agent/*.txt.erb').map do |file|
      File.basename(file, '.txt.erb').tr('_', ' ')
    end.excluding('instructions', 'common', 'description')
  end
end
