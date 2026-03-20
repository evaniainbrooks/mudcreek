OmniAuth.config.test_mode = true
OmniAuth.config.logger = Rails.logger

RSpec.configure do |config|
  config.after(:each) do
    OmniAuth.config.mock_auth.clear
  end
end
