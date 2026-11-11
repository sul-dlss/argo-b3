# frozen_string_literal: true

module Contents
  module Validators
    # Validates that every file of a dark object is dark and neither published nor shelved.
    # Violations are errors, since cocina requires the files of a dark object to be dark and unshelved.
    class DarkFiles < Default
      # @return [Contents::Validators::Result]
      def call
        content_file_sets.each.with_index(1) do |content_file_set, index|
          name = resource_name_for(content_file_set:, index:)
          content_file_set.content_files.each { |content_file| validate_content_file(content_file:, name:) }
        end

        result
      end

      private

      def validate_content_file(content_file:, name:)
        file_name = "#{name} file #{content_file.filepath}"
        errors << "#{file_name} must be dark because the object is dark." unless dark_file?(content_file)
        return unless content_file.publish || content_file.shelve

        errors << "#{file_name} must not be published or shelved because the object is dark."
      end

      def dark_file?(content_file)
        AccessRightsSupport.dark?(view: content_file.view, download: content_file.download,
                                  location: content_file.location)
      end
    end
  end
end
