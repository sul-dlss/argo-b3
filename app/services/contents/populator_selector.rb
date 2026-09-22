# frozen_string_literal: true

module Contents
  # Selects the populator to use for a Content and explains the selection.
  #
  # The populator for a content type (e.g., Book for a book) may not be able to handle a particular
  # content, e.g., when the files of a book are organized into folders. In that case the fallback
  # populator is used instead, and the reasons are provided so that they can be shared with the user.
  #
  # Note that selecting a populator depends on the mime types of the binaries, so this populates the mime
  # type of any unassociated ContentFileBinary that does not yet have one. That is, calling this writes
  # to the database. Populating the mime type is idempotent, so calling this repeatedly is harmless.
  class PopulatorSelector
    # @!attribute populator_for_content_type
    #   @return [Class] the populator for the content type of the object
    # @!attribute actual_populator
    #   @return [Class] the populator to use, which is the fallback populator when there are reasons
    # @!attribute reasons
    #   @return [Array<Symbol>] the reasons that the populator for the content type is not being used;
    #     empty when it is being used
    Result = Struct.new(:populator_for_content_type, :actual_populator, :reasons)

    # The populator for content types without a populator of their own, and for when the populator for
    # the content type cannot handle the content.
    FALLBACK_POPULATOR = Contents::Populators::FileSetPerFile

    POPULATORS_FOR_CONTENT_TYPES = {
      Cocina::Models::ObjectType.book => Contents::Populators::Book
    }.freeze

    # The populators that can be selected, keyed by their demodulized name (e.g., FileSetPerFile).
    POPULATORS_BY_NAME = [FALLBACK_POPULATOR, *POPULATORS_FOR_CONTENT_TYPES.values]
                         .index_by { |populator| populator.name.demodulize }.freeze

    def self.call(...)
      new(...).call
    end

    # @param [Content] content
    # @param [Cocina::Models::DROWithMetadata] cocina_object
    def initialize(content:, cocina_object:)
      @content = content
      @cocina_object = cocina_object
    end

    # @return [Result] the selected populator and why it was selected
    def call
      update_mime_types_for_unassociated!

      reasons = populator_for_content_type.disqualifying_reasons(content:, cocina_object:)
      Result.new(populator_for_content_type:,
                 actual_populator: reasons.any? ? FALLBACK_POPULATOR : populator_for_content_type,
                 reasons:)
    end

    private

    attr_reader :content, :cocina_object

    def populator_for_content_type
      POPULATORS_FOR_CONTENT_TYPES.fetch(cocina_object.type, FALLBACK_POPULATOR)
    end

    # A mime type is needed both for selecting a populator and for performing the structuring.
    # The association is reset afterwards so that a populator does not decide whether it can handle the
    # content from binaries that were loaded before their mime types were populated.
    def update_mime_types_for_unassociated!
      content.content_file_binaries.unassociated.find_each do |content_file_binary|
        Contents::Analyzer.call(content_file_binary:, mime_type_only: true)
      end
      content.content_file_binaries.reset
    end
  end
end
