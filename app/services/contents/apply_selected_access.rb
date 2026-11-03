# frozen_string_literal: true

module Contents
  # Applies the access selected on the manage files form (which may not have been saved yet) to a cocina object,
  # so that structuring and validating the structure use it.
  class ApplySelectedAccess
    def self.call(...)
      new(...).call
    end

    # @param [Cocina::Models::DROWithMetadata] cocina_object
    # @param [Hash, ActionController::Parameters] params the ContentsItemForm::ACCESS_PARAMS that were selected
    def initialize(cocina_object:, params:)
      @cocina_object = cocina_object
      @params = params.to_h.symbolize_keys.slice(*ContentsItemForm::ACCESS_PARAMS)
    end

    # @return [Cocina::Models::DROWithMetadata] the cocina object, with the selected access when there is any
    def call
      return cocina_object if params.empty?

      # Not validated, since a selection that is still being made may not yet be a valid combination.
      cocina_object.new(access: access_props, validate: false)
    end

    private

    attr_reader :cocina_object, :params

    def access_props
      cocina_object.access.to_h.except(:embargo)
                   .merge(rights_props('access'), embargo: (embargo_props if embargo?))
                   .compact
    end

    # @param prefix [String] 'access' or 'embargo'
    # @return [Hash] view, download, and location, which is omitted when blank (matching DroMutator)
    def rights_props(prefix)
      { view: params[:"#{prefix}_view"], download: params[:"#{prefix}_download"],
        location: params[:"#{prefix}_location"].presence }
    end

    # The release date may not be entered yet, but files still get the access once the embargo ends.
    def embargo?
      ActiveModel::Type::Boolean.new.cast(params[:with_embargo])
    end

    # Cocina requires a release date, so a placeholder stands in until one is entered; structuring does not use it.
    def embargo_props
      { releaseDate: params[:embargo_release_date].presence || Time.zone.today.to_s,
        **rights_props('embargo') }.compact
    end
  end
end
