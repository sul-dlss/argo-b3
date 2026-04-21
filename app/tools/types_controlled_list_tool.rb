# frozen_string_literal: true

class TypesControlledListTool < RubyLLM::Tool
  description 'Gets controlled list of valid values for a given type.'

  params do
    string :name, description: 'Name of the type for which to get controlled list of valid values.'
  end

  def execute(name:)
    Rails.logger.info "TypesControlledListTool called with name: #{name}"
    unless all_types.key?(name)
      return "No controlled list of valid values found for type: #{name}. Valid names are: #{all_types.keys.join(', ')}"
    end

    entries = all_types[name].map { |entry| "- #{type_for(entry)}" }.join("\n")
    "Controlled list of valid values for #{name}:\n#{entries}"
  end

  private

  def all_types
    @@all_types ||= begin
      spec = Gem::Specification.find_by_name('cocina-models')
      file_path = File.join(spec.gem_dir, 'description_types.yml')
      YAML.load_file(file_path)
    end
  end

  def type_for(entry)
    if entry['description'].present?
      "#{entry['value']}: #{entry['description']}"
    else
      entry['value']
    end
  end
end
