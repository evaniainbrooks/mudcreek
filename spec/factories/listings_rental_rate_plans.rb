FactoryBot.define do
  factory :listings_rental_rate_plan, class: "Listings::RentalRatePlan" do
    association :listing
    sequence(:label) { |n| "Plan #{n}" }
    duration_minutes { 60 }
    price_cents      { 1500 }
  end
end
