# When running specs with a real browser (Selenium), Capybara starts a local
# Puma server and the browser connects to it at 127.0.0.1:port. The global
# app_host "http://example.com" (set in spec/support/tenant.rb for rack_test)
# would cause the browser to hit the live internet instead. This around hook
# temporarily clears app_host so Capybara falls back to the actual test server
# address. TenantResolution resolves the tenant via Tenant.find_by!(default:
# true) for requests with no subdomain, which matches the default tenant
# created in the system spec before hook.
Capybara.configure do |config|
  config.server = :puma, { Silent: true }
end

# Register a headless Chrome driver with a large window so the full admin form
# is visible and Selenium can click buttons without scroll-position issues.
Capybara.register_driver :selenium_chrome_headless_xl do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1440,900")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

RSpec.configure do |config|
  config.around(:each, :js) do |example|
    original_host = Capybara.app_host
    Capybara.app_host = nil
    example.run
  ensure
    Capybara.app_host = original_host
  end
end
