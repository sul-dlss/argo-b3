# frozen_string_literal: true

module Contents
  # Updates the Numbered Labels of a Content's resources (e.g., after reordering them): each label that is a name
  # followed by a number (e.g., Page 3, Video file 2) is renumbered in resource order, separately for each name.
  # Other labels (e.g., Cover, Page 3a, Video file 1 transcript) are left unchanged and are not counted.
  class LabelUpdater
    NUMBERED_LABEL = /\A(?<name>.*\S) \d+\z/

    def self.call(...)
      new(...).call
    end

    # @param [Content] content
    def initialize(content:)
      @content = content
    end

    def call
      counts = Hash.new(0)
      ContentFileSet.transaction do
        content.content_file_sets.each do |content_file_set|
          name = NUMBERED_LABEL.match(content_file_set.label.to_s)&.[](:name)
          next unless name

          counts[name] += 1
          content_file_set.update!(label: "#{name} #{counts[name]}")
        end
      end
    end

    private

    attr_reader :content
  end
end
