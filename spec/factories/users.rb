FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password" }

    trait :super_admin do
      after(:create) do |user|
        role = Role.find_or_create_by!(name: "test_super_admin") do |r|
          r.description = "Full access for tests."
        end
        %w[Listing User Role Permission Listings::Category].each do |resource|
          %w[index show create update destroy].each do |action|
            role.permissions.find_or_create_by!(resource: resource, action: action)
          end
        end
        user.update_column(:role_id, role.id)
      end
    end
  end
end
