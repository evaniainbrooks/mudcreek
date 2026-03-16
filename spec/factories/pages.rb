FactoryBot.define do
  factory :page do
    title { Faker::Lorem.unique.words(number: 3).join(" ").titleize }
    slug  { title.parameterize }
    published      { false }
    show_in_nav    { false }
    show_in_footer { false }
    position       { 0 }

    trait :published do
      published { true }
    end

    trait :in_nav do
      published { true }
      show_in_nav { true }
    end

    trait :in_footer do
      published { true }
      show_in_footer { true }
    end
  end
end
