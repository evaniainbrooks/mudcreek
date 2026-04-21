FactoryBot.define do
  factory :qr_scan do
    association :qr_code
    ip_address { "127.0.0.1" }
    user_agent { "Mozilla/5.0" }
  end
end
