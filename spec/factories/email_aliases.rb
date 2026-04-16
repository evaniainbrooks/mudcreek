FactoryBot.define do
  factory :email_alias do
    sequence(:external_id) { |n| n }
    sequence(:alias)       { |n| "alias#{n}@example.com" }
    forward                { "forward@example.com" }
  end
end
