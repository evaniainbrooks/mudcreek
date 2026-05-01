FactoryBot.define do
  factory :discipline do
    sequence(:name) { |n| "Discipline #{n}" }
  end
end
