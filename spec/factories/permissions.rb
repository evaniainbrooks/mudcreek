FactoryBot.define do
  factory :permission do
    role
    resource { "Listing" }
    action { "index" }
  end
end
