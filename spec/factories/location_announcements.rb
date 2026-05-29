FactoryBot.define do
  factory :location_announcement do
    association :location
    association :sent_by, factory: :user
    sequence(:subject) { |n| "Announcement #{n}" }
    body { "Announcement body text." }
    sent_at { nil }
  end
end
