FactoryBot.define do
  factory :listings_category, class: "Listings::Category" do
    sequence(:name) { |n| "Category #{n}" }
  end
end
