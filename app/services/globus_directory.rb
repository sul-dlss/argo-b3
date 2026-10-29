# frozen_string_literal: true

# A user's Globus directory, which users transfer files into.
# The directory is also available locally on the Globus mount
# (where the root of the Globus collection is Settings.globus.directory).
class GlobusDirectory
  # @param druid [String]
  # @param user [User]
  # @return [GlobusDirectory] the user's directory for an object
  def self.for_object(druid:, user:)
    new(path: "#{Settings.globus.uploads_path}/#{user.sunetid}/objects/#{DruidSupport.bare_druid_from(druid)}",
        user:)
  end

  # Druids are not known before a Multi-Item Deposit's manifest is read, so the directory is named with a timestamp
  # @param user [User]
  # @return [GlobusDirectory] a new directory for a Multi-Item Deposit
  def self.for_multi_item_deposit(user:)
    new(path: "#{Settings.globus.uploads_path}/#{user.sunetid}/#{Time.current.strftime('%Y-%m-%d-%H-%M-%S-%L')}",
        user:)
  end

  # @param path [String] the path of the directory on the Globus endpoint
  # @param user [User]
  def initialize(path:, user:)
    @path = path
    @user = user
  end

  # @return [String] the path of the directory on the Globus endpoint
  attr_reader :path

  # @return [String] the path of the directory on the local Globus mount
  def local_path
    File.join(Settings.globus.directory, path)
  end

  # @return [String] a link to the Globus file manager with the directory as the destination
  def url
    params = { destination_id: Settings.globus.endpoint_id, destination_path: path }
    "https://app.globus.org/file-manager?#{params.to_query}"
  end

  # Checks with Globus (rather than just the local mount) so that a directory created without write access
  # (e.g., because allowing writes failed) is not treated as ready for the user.
  # @return [Boolean] true if the user can write to the directory; false if not or if Globus returned an
  #   error (which is reported to Honeybadger)
  def writable?
    return File.directory?(local_path) if test_mode?

    GlobusClient.writable?(path:, user_id: user.email_address)
  rescue GlobusClient::Error, Faraday::Error => e
    Honeybadger.notify(e, context: { path: })
    false
  end

  # Creates the directory and allows the user to write to it.
  # @return [Boolean] true if created; false if Globus returned an error (which is reported to Honeybadger)
  def create
    if test_mode?
      FileUtils.mkdir_p(local_path)
    else
      GlobusClient.mkdir(path:, user_id: user.email_address, notify_email: false)
    end
    true
  rescue GlobusClient::Error, Faraday::Error => e
    Honeybadger.notify(e, context: { path: })
    false
  end

  private

  attr_reader :user

  # Simulates Globus directory creation in development, if settings indicate.
  def test_mode?
    Settings.globus.test_mode && Rails.env.development?
  end
end
