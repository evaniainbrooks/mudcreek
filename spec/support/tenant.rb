# Use a host with no subdomain so ApplicationController#set_current_tenant
# falls through to Tenant.find_by!(default: true) instead of looking up a
# tenant by the "www" subdomain that Capybara uses by default.
Capybara.configure do |config|
  config.app_host = "http://example.com"
end

# Creates a default tenant within each test's transaction and sets
# Current.tenant so FactoryBot records created in the test body are scoped to
# the correct tenant via MultiTenant#set_tenant.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    Current.tenant = Tenant.create!(key: "test", default: true)
  end
end
