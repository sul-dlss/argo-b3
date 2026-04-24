class CocinaDescriptionSchemaGenerator
  def self.call
    new.call
  end

  def call
    full_schema.dig('$defs', 'Description').dup.tap do |schema|
      # refs_from(description_def)
      schema['$defs'] = referenced_definitions.to_h do |definition_name|
        [definition_name, full_schema.dig('$defs', definition_name)]
      end
    end
  end

  private

  def full_schema
    @full_schema ||= begin
      spec = Gem::Specification.find_by_name('cocina-models')
      file_path = File.join(spec.gem_dir, 'schema.json')
      JSON.parse(File.read(file_path))
    end
  end

  def description_definition
    @description_definition ||= full_schema.dig('$defs', 'Description')
  end

  def referenced_definitions
    @referenced_definitions ||= [].tap do |refs|
      refs_from(description_definition, refs)
    end
  end

  def refs_from(obj, refs)
    case obj
    when Hash
      if obj.key?('$ref')
        definition_name = obj['$ref'].split('/').last
        definition = full_schema.dig('$defs', definition_name)
        return if refs.include?(definition_name)

        refs << definition_name
        refs_from(definition, refs)
      end
      obj.each_value do |value|
        refs_from(value, refs)
      end
    when Array
      obj.each do |item|
        refs_from(item, refs)
      end
    end
  end
end
