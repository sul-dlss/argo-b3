# frozen_string_literal: true

# This is to prevent the animation from running in the system tests which can make the tests flaky.
Capybara.disable_animation = true

# Unique per process for parallel tests
DOWNLOAD_PATH = Rails.root.join("tmp/downloads/#{Process.pid}").to_s

Capybara.register_driver :selenium_chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: default_chrome_options).tap do |driver|
    add_download_behavior(driver)
  end
end

Capybara.register_driver :selenium_headless_chrome do |app|
  opts = default_chrome_options
  opts.add_argument('--headless=new') # or --headless
  opts.add_argument('--window-size=1400,1400')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: opts).tap do |driver|
    add_download_behavior(driver)
  end
end

def default_chrome_options
  Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    # Reduce prompts in chrome
    opts.add_argument('--no-first-run')
    opts.add_argument('--no-default-browser-check')
    opts.add_argument('--disable-popup-blocking')
    # Disable Web Share dialogs if site triggers navigator.share
    opts.add_argument('--disable-features=WebShare,WebShareFile')
    # Bypass media permission UI (camera/mic) and screen capture prompts
    opts.add_argument('--use-fake-ui-for-media-stream')
    opts.add_argument('--use-fake-device-for-media-stream')
    # Allow screen capture on http (localhost) and auto-select a source
    opts.add_argument('--allow-http-screen-capture')
    opts.add_argument('--auto-select-desktop-capture-source=Entire screen')
  end
end

def add_download_behavior(driver)
  driver.browser.execute_cdp('Page.setDownloadBehavior', behavior: 'allow', downloadPath: DOWNLOAD_PATH)
rescue StandardError => e
  Rails.logger.info("CDP setDownloadBehavior failed: #{e.message}")
end

RSpec.configure do |config|
  config.prepend_before(:example, type: :system) do |example|
    # If you can't use Cyperful, a headed test can be helpful for authoring system specs.
    if ENV['CYPERFUL'] || example.metadata[:headed_test]
      # Cyperful only supports Selenium + Chrome
      driven_by :selenium_chrome
    elsif example.metadata[:rack_test]
      # Rack tests are faster than Selenium, but they don't support JavaScript
      driven_by :rack_test, options: { name: 'rack_test' }
    else
      driven_by :selenium_headless_chrome
    end
  end

  # This will output the browser console logs after each system test
  config.after(:each, type: :system) do |example|
    next if example.metadata[:rack_test] || ENV['CYPERFUL'].present?

    Rails.logger.info('Browser log entries from system spec run include:')
    Capybara.page.driver.browser.logs.get(:browser).each do |log_entry|
      Rails.logger.info("* #{log_entry}")
    end
  end
end
