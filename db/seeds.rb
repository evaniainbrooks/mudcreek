default_password = Rails.application.credentials.seeds.default_user_password

User.find_or_create_by!(email_address: "admin@mudcreek") do |u|
  u.password = default_password
  u.password_confirmation = default_password
end

# Generate fake users for dev pagination testing
60.times do
  User.find_or_create_by!(email_address: Faker::Internet.unique.email) do |u|
    password = Faker::Internet.password
    u.password = password
    u.password_confirmation = password
  end
end

puts "Seeded #{User.count} users."
