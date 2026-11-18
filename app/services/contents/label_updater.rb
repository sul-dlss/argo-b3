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

    # Resources are visited in position order, keeping a count per name, so each Numbered Label gets the next number
    # for its name (e.g., Page 1, Video file 1, Page 2). A label that doesn't match is skipped without being counted.
    # The transaction keeps the labels consistent: either every Numbered Label is updated, or none is.
    def call
      counts = Hash.new(0)
      ContentFileSet.transaction do
        content.content_file_sets.each do |content_file_set|
          name = content_file_set.label.to_s[NUMBERED_LABEL, :name]
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
