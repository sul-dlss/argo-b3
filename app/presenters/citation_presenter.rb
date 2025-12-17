# frozen_string_literal: true

# Presenter for generating a citation string for a document
# used as placeholder text when no thumbnail is available
class CitationPresenter
  def initialize(result:, italicize: true)
    @result = result
    @italicize = italicize
  end

  def call
    citation = ''
    citation += "#{author} " if author.present?
    if title_display.present?
      citation += @italicize ? "<em>#{title_display}</em>" : title_display
    end
    origin_info = [publisher, place, mods_created_date].compact.join(', ')
    citation += ": #{origin_info}" if origin_info.present?
    citation.html_safe # rubocop:disable Rails/OutputSafety
  end

  attr_reader :result

  private

  def author
    result.author
  end

  def title_display
    result.title
  end

  def publisher
    result.publisher&.first
  end

  def place
    result.publication_place&.first
  end

  def mods_created_date
    result.publication_date
  end
end
