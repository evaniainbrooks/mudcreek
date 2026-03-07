RSpec.configure do |config|
  config.before(:each) do
    Prosopite.scan
  end

  config.after(:each) do
    Prosopite.finish
  end
end

Prosopite.raise = true
