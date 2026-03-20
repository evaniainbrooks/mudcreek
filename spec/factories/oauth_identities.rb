FactoryBot.define do
  factory :oauth_identity do
    association :user
    provider { "google" }
    sequence(:uid) { |n| "google_uid_#{n}" }
    email { user.email_address }
  end
end
