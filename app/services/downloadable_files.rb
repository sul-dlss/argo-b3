# frozen_string_literal: true

# The files of a Content that a Download files bulk action zips: those available, once per filepath.
class DownloadableFiles
  def self.max_size
    Settings.bulk_actions.download_files_max_size
  end

  # @param content [Content]
  # @param file_availability [FileAvailability]
  def initialize(content:, file_availability:)
    @content = content
    @file_availability = file_availability
  end

  # @return [Array<ContentFile>]
  def content_files
    @content_files ||= content.content_file_sets.includes(content_files: :content_file_binary)
                              .flat_map(&:content_files)
                              .uniq(&:filepath)
                              .select { |content_file| file_availability.available?(content_file) }
  end

  delegate :empty?, :size, to: :content_files

  # @return [Integer] bytes
  def total_size
    content_files.sum { |content_file| content_file.size.to_i }
  end

  def too_large?
    total_size > self.class.max_size
  end

  private

  attr_reader :content, :file_availability
end
