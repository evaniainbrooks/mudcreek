FactoryBot.define do
  factory :listings_delivery_method_set, class: "Listings::DeliveryMethodSet" do
    sequence(:name) { |n| "Delivery Method Set #{n}" }
  end
end
