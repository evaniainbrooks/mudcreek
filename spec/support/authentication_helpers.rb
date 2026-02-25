module AuthenticationHelpers
  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: password
    click_button "Sign in"
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :system
end
