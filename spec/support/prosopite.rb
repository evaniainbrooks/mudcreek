RSpec.configure do |config|
  config.before(:each) do |example|
    Prosopite.scan unless example.metadata[:skip_n_plus_one]
  end

  config.after(:each) do |example|
    Prosopite.finish unless example.metadata[:skip_n_plus_one]
  end
end

Prosopite.raise = true
