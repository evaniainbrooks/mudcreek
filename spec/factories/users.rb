FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password" }
    first_name { "Test" }
    last_name { "User" }
    activated_at { Time.current }

    trait :unactivated do
      activated_at { nil }
    end

    trait :super_admin do
      after(:create) do |user|
        role = Role.find_or_create_by!(name: "test_super_admin") do |r|
          r.description = "Full access for tests."
        end
        role.grant_all_permissions!
        user.update_column(:role_id, role.id)
      end
    end
  end
end
