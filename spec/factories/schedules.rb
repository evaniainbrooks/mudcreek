FactoryBot.define do
  factory :schedule do
    association :location
    sequence(:name) { |n| "Schedule #{n}" }
  end

  factory :schedule_event do
    association :schedule
    sequence(:summary) { |n| "Event #{n}" }
    bookable { false }
  end

  factory :schedule_event_session do
    association :schedule_event
    sequence(:occurs_on) { |n| Date.current + n.days }
  end

  factory :schedule_event_pass do
    association :user
    credits_remaining { 10 }
    expires_at        { nil }
  end

  factory :schedule_event_registration do
    association :user
    association :schedule_event_session
    status { :confirmed }
  end
end
