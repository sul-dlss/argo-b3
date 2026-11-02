# frozen_string_literal: true

module Contents
  # Applies the access selected on the manage files form (which may not have been saved yet) to a cocina object,
  # so that structuring and validating the structure use it. The embargo is not applied, since files get the
  # object's current access (see Contents::DefaultFileAccess).
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

    # The location is omitted when blank, matching DroMutator.
    def access_props
      cocina_object.access.to_h.except(:location)
                   .merge(view: params[:access_view], download: params[:access_download],
                          location: params[:access_location].presence)
                   .compact
    end
  end
end
