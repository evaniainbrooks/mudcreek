FactoryBot.define do
  factory :listings_property, class: "Listings::Property" do
    association :property_set, factory: :listings_property_set
    sequence(:name) { |n| "Property #{n}" }
    value { "Example Value" }
  end
end
