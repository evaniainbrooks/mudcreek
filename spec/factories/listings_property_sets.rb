FactoryBot.define do
  factory :listings_property_set, class: "Listings::PropertySet" do
    sequence(:name) { |n| "Property Set #{n}" }
  end
end
