FactoryBot.define do
  factory :inquiry_form do
    sequence(:name) { |n| "Inquiry Form #{n}" }
    slug            { name.parameterize }
    published       { true }
    association :notification_recipient, factory: :user

    trait :published do
      published { true }
    end

    trait :unpublished do
      published { false }
    end
  end
end
