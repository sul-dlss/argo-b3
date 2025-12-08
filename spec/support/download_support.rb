# frozen_string_literal: true

# This depends on DOWNLOAD_PATH being defined and selenium being correctly configured in capybara.rb

def with_download(filename, cleanup: true)
  filepath = File.join(DOWNLOAD_PATH, filename)
  FileUtils.mkdir_p(DOWNLOAD_PATH)
  FileUtils.rm_f(filepath)

  # Perform the action that triggers the download
  yield

  wait_and_read_download(filepath)
ensure
  FileUtils.rm_f(filepath) if cleanup
end

def wait_and_read_download(filepath)
  Timeout.timeout(15) do
    sleep 0.25 until File.exist?(filepath) && !File.exist?("#{filepath}.crdownload")
  end
  File.read(filepath)
end
