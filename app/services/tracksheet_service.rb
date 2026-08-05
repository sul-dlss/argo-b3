# frozen_string_literal: true

require 'prawn/measurement_extensions'
require 'barby/barcode/code_128'
require 'barby/outputter/prawn_outputter'

# Generates a Prawn PDF tracking sheet for a single digital object.
class TracksheetService
  # Directory containing the vendored TrueType fonts used to render the PDF.
  # A TTF font is required (instead of Prawn's built-in AFM fonts) so that
  # titles and other metadata containing UTF-8 characters can be rendered
  # without raising Prawn::Errors::IncompatibleStringEncoding.
  FONT_DIR = Rails.root.join('vendor/fonts')

  # Pan-Unicode font used in place of the built-in "Courier" AFM font. GNU
  # Unifont covers the entire Basic Multilingual Plane in a single TrueType
  # file (Latin, Cyrillic, Greek, Arabic, CJK, Hangul, Kana, etc.), so titles
  # and metadata in any of those scripts render rather than dropping out. It is
  # a 16px bitmap font, so glyphs render "chunky"; that is an accepted tradeoff
  # for universal coverage on this utilitarian tracking sheet. Its combining
  # marks are zero-advance, so diacritics and the ALA-LC "i͡a" tie (U+0361)
  # overprint their base characters. Unifont ships a single weight, so every
  # style variant below points at the same file.
  FONT_FAMILY = 'Unifont'

  def self.call(...)
    new(...).call
  end

  # @param solr_doc_presenters [Array<SolrDocPresenter>] presenters for the object to render
  def initialize(solr_doc_presenters:)
    @solr_doc_presenters = solr_doc_presenters
  end

  # @return [Prawn::Document] single-page PDF tracking sheet
  def call
    Prawn::Document.new(page_size: [5.5.in, 8.5.in]).tap do |pdf|
      register_fonts(pdf)
      pdf.font(FONT_FAMILY)
      solr_doc_presenters.each_with_index do |solr_doc_presenter, index|
        generate_tracking_sheet(solr_doc_presenter, pdf)
        pdf.start_new_page unless index + 1 == solr_doc_presenters.length
      end
    end
  end

  private

  attr_reader :solr_doc_presenters

  # Registers the vendored TrueType font family with the PDF document so that
  # UTF-8 text can be rendered.
  # @param pdf [Prawn::Document] document being built (document is modified)
  def register_fonts(pdf)
    unifont = FONT_DIR.join('unifont-15.0.06.ttf').to_s
    pdf.font_families.update(
      FONT_FAMILY => { normal: unifont, bold: unifont, italic: unifont, bold_italic: unifont }
    )
  end

  def generate_tracking_sheet(solr_doc_presenter, pdf) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    bc_width = 2.25.in
    bc_height = 0.75.in

    top_margin = pdf.page.size[1] - pdf.bounds.absolute_top

    barcode = Barby::Code128B.new(solr_doc_presenter.bare_druid)
    barcode.annotate_pdf(
      pdf,
      width: bc_width,
      height: bc_height,
      x: (pdf.bounds.width / 2) - (bc_width / 2),
      y: (pdf.bounds.height - bc_height)
    )

    pdf.y -= (bc_height + 0.25.in)
    pdf.text solr_doc_presenter.bare_druid, size: 15, style: :bold, align: :center
    pdf.y -= 0.5.in

    pdf.font(FONT_FAMILY, size: 10)
    pdf.table(doc_to_table(solr_doc_presenter), column_widths: [100, 224], cell_style: { borders: [], padding: 0.pt })

    pdf.y -= 0.5.in

    pdf.font_size = 14
    pdf.text 'Tracking:'
    pdf.text ' '

    baseline = pdf.y - top_margin - pdf.font.ascender
    pdf.rectangle([0, baseline + pdf.font.ascender], pdf.font.ascender, pdf.font.ascender)
    pdf.indent(pdf.font.ascender + 4.pt) do
      pdf.text 'Scanned by:'
      pdf.indent(pdf.width_of('Scanned by:') + 0.125.in) do
        pdf.line 0, baseline, pdf.bounds.width, baseline
      end
    end
    pdf.stroke

    pdf.y -= 0.5.in
    pdf.text('Notes:')
    pdf.stroke do
      while pdf.y >= pdf.bounds.absolute_bottom
        baseline = pdf.y - top_margin - pdf.font.height
        pdf.line 0, baseline, pdf.bounds.width, baseline
        pdf.y -= pdf.font.height * 1.5
      end
    end
    pdf
  end

  # @return [Array<Array<String>>] table data suitable for Prawn's pdf.table
  def doc_to_table(solr_doc_presenter) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
    table_data = []

    table_data.push(['Object Label:', normalize(solr_doc_presenter.title).truncate(110)])

    project = solr_doc_presenter.projects&.first
    table_data.push(['Project Name:', normalize(project)]) if project

    tags = Array(solr_doc_presenter.other_tags).filter_map do |tag|
      /^Project\s*:/.match?(tag) ? nil : normalize(tag).gsub(/\s+/, Prawn::Text::NBSP)
    end
    table_data.push(['Tags:', tags.join("\n")]) unless tags.empty?

    catalog_record_id = Array(solr_doc_presenter.catalog_record_id).first
    table_data.push(['Folio Instance HRID:', catalog_record_id]) if catalog_record_id.present?

    source_id = solr_doc_presenter.source_id
    table_data.push(['Source ID:', source_id]) if source_id.present?

    barcode = solr_doc_presenter.barcodes&.first
    table_data.push(['Barcode:', barcode]) if barcode.present?

    table_data.push(['Date Printed:', Time.zone.now.strftime('%c')])
    table_data
  end

  # Normalizes text to Unicode NFC (canonical composition) so that composed
  # diacritics (e.g. "e" + combining acute) render as a single glyph in the PDF
  # rather than as a base letter with a separately positioned combining mark.
  # @param value [String, nil]
  # @return [String]
  def normalize(value) = value.to_s.unicode_normalize(:nfc)
end
