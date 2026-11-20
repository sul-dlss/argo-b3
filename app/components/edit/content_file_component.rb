# frozen_string_literal: true

module Edit
  # Component for editing a file within a file set (resource), as a row of the resource's files table
  # (see Edit::FileSetComponent).
  # The row markup is the contract with the content-files Stimulus controller
  # (see app/javascript/controllers/content_files_controller.js) and the access-rights Stimulus controller.
  # The form's object must provide id, filepath, view, download, location, publish, preserve,
  # corrected_for_accessibility, and _destroy, plus the attributes required by the components it renders.
  class ContentFileComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder] a nested form builder for a ContentFileForm
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    delegate :filepath, to: :content_file_form

    def content_file_form
      form.object
    end

    def view_options
      Edit::AccessRightsComponent.view_options(citation_only: false)
    end

    delegate :download_options, :location_options, to: Edit::AccessRightsComponent

    # The publish or preserve error is shown under Publish (see ContentFileForm), so Preserve, which also fixes it,
    # is marked invalid and described by that error too.
    def preserve_aria
      return {} if content_file_form.errors[:publish].blank?

      { invalid: true, describedby: form.field_id(:publish, 'error') }
    end

    # The visually hidden label of an input in the row, which names the file since the column headers
    # do not label the inputs.
    # The label components mark their text as HTML safe, so the filepath is escaped here.
    # @param field [Symbol] the field, e.g., :view
    def row_label(field)
      ERB::Util.html_escape(t("edit.content_file_sets.fields.content_files.#{field}.row_label", filepath:))
    end
  end
end
