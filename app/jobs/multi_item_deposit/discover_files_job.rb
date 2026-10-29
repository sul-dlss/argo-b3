# frozen_string_literal: true

module MultiItemDeposit
  # Discovery for one Item Deposit: checks the object and its folder on the mount, recording discovery errors
  # and warnings, and when there are no errors, records the files in a new mutable Content.
  class DiscoverFilesJob < ApplicationJob
    include ActionPolicy::Behaviour

    MAX_FILE_SIZE = 4 * (1000**4) # 4 TB

    # @param item_deposit_action [ItemDepositAction]
    # @param effective_groups [Array<String>] the requesting user's authorization workgroups
    def perform(item_deposit_action:, effective_groups:)
      @item_deposit_action = item_deposit_action
      @effective_groups = effective_groups
      item_deposit_action.assign_attributes(discovery_errors: [], discovery_warnings: [])

      check_folder
      check_object
      discover! if item_deposit_action.discovery_errors.empty?
      item_deposit_action.save!
    rescue StandardError => e
      handle_error(e)
    end

    private

    attr_reader :item_deposit_action, :effective_groups, :content

    delegate :druid, to: :item_deposit_action

    def check_folder
      return add_error(:folder_not_found, path: item_deposit_action.path) unless File.directory?(folder_path)

      check_folder_contents
    end

    def check_folder_contents
      return add_error(:no_files, path: item_deposit_action.path) if filepaths.empty?

      check_file_sizes
      add_warning(:empty_folders, paths: join(empty_folder_paths)) if empty_folder_paths.any?
    rescue Contents::MountDiscoverer::InvalidFilepathsError => e
      item_deposit_action.discovery_errors << e.message
    end

    def check_file_sizes
      too_large_filepaths = filepaths.select { |filepath| file_size(filepath) > MAX_FILE_SIZE }
      add_error(:files_too_large, filepaths: join(too_large_filepaths)) if too_large_filepaths.any?
      empty_filepaths = filepaths.select { |filepath| file_size(filepath).zero? }
      add_warning(:empty_files, filepaths: join(empty_filepaths)) if empty_filepaths.any?
    end

    def check_object
      return add_error(:object_not_found) if cocina_object.nil?
      return add_error(:not_item) unless CocinaSupport.item?(cocina_object)
      return add_error(:not_authorized) unless update_allowed?

      check_version
      check_existing_content
    end

    def check_version
      if version_service.open?
        add_warning(:not_closeable) unless version_service.closeable?
      else
        add_warning(:not_openable) unless version_service.openable?
      end
    end

    # An existing mutable Content would conflict with the new one (unique index on druid, lock, and immutable).
    def check_existing_content
      add_error(:content_in_progress) if existing_content&.staging? || existing_content&.discovering?
    end

    def discover!
      discard_existing_content
      @content = Content.create!(druid:, lock: cocina_object.lock, immutable: false, mount_state: 'discovering')
      Contents::MountDiscoverer.call(content:, mount_path: folder_path, file_location:)
      content.discovery_completed!
      item_deposit_action.assign_attributes(content:, initial_version: initial_version?, content_type:)
    end

    def discard_existing_content
      return if existing_content.nil?

      existing_content.destroy!
      add_warning(:discarded_content)
    end

    # Unsaved changes (e.g., the destroyed Content) are discarded, but the errors and warnings so far are kept.
    def handle_error(error)
      Rails.logger.error(error.full_message)
      Honeybadger.notify(error)
      content&.destroy!
      discovery_errors = item_deposit_action.discovery_errors + [message(:errors, :unexpected)]
      discovery_warnings = item_deposit_action.discovery_warnings
      item_deposit_action.reload.update!(discovery_errors:, discovery_warnings:)
    end

    def update_allowed?
      Current.set(effective_groups:) do
        allowed_to?(:update?, cocina_object, with: ObjectPolicy,
                                             context: { user: item_deposit_action.user })
      end
    end

    def cocina_object
      return @cocina_object if defined?(@cocina_object)

      @cocina_object = begin
        Sdr::Repository.find(druid:)
      rescue Sdr::Repository::NotFoundResponse
        nil
      end
    end

    def existing_content
      return @existing_content if defined?(@existing_content)

      @existing_content = Content.find_by(druid:, lock: cocina_object.lock, immutable: false)
    end

    def version_service
      @version_service ||= Sdr::VersionService.new(druid:)
    end

    def initial_version?
      version_service.version == 1 && version_service.open?
    end

    def content_type
      UriSupport.last(uri: cocina_object.type)
    end

    def file_location
      item_deposit_action.file_location.to_sym
    end

    def folder_path
      @folder_path ||= File.join(item_deposit_action.files_path, item_deposit_action.path)
    end

    def filepaths
      @filepaths ||= Contents::MountDiscoverer.filepaths(mount_path: folder_path)
    end

    def file_size(filepath)
      File.size(File.join(folder_path, filepath))
    end

    # Only the topmost folder that contains no (non-ignored) files is reported.
    def empty_folder_paths
      @empty_folder_paths ||= begin
        empty_paths = subfolder_paths.reject do |subfolder_path|
          filepaths.any? { |filepath| filepath.start_with?("#{subfolder_path}/") }
        end
        empty_paths.reject { |empty_path| empty_paths.include?(File.dirname(empty_path)) }
      end
    end

    # @return [Array<String>] the folders (relative to the item's folder) that are not ignored
    def subfolder_paths
      Dir.glob('**/*', File::FNM_DOTMATCH, base: folder_path)
         .select { |path| path != '.' && File.directory?(File.join(folder_path, path)) }
         .reject { |path| IgnoreFileService.call(filepath: path) }
    end

    def join(paths)
      paths.sort.join(', ')
    end

    def add_error(key, **)
      item_deposit_action.discovery_errors << message(:errors, key, **)
    end

    def add_warning(key, **)
      item_deposit_action.discovery_warnings << message(:warnings, key, **)
    end

    def message(kind, key, **)
      I18n.t(key, scope: [:multi_item_deposit, :discover_files, kind], **)
    end
  end
end
