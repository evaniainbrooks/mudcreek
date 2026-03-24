FactoryBot.define do
  factory :location do
    sequence(:name) { |n| "Location #{n}" }

    trait :with_address do
      after(:create) do |location|
        location.create_address!(
          address_type: "profile",
          street_address: "123 Main St",
          city: "Anytown",
          province: "ON",
          postal_code: "K1A 0A1",
          country: "CA"
        )
      end
    end
  end
end
