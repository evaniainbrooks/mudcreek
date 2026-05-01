FactoryBot.define do
  factory :rank_award do
    association :rank
    association :rankable, factory: :user
    awarded_at { Date.current }
    stripes { 0 }
  end
end
