FactoryBot.define do
  factory :inquiry do
    association :inquiry_form
    name    { "Test User" }
    email   { "test@example.com" }
    message { "Hello, I have a question." }
    phone   { nil }
  end
end
