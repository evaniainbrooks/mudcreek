RSpec.configure do |config|
  config.before(:each, type: :request) do
    allow(SquareClient).to receive(:application_id).and_return("test_app_id")
    allow(SquareClient).to receive(:location_id).and_return("test_location_id")
  end
end
