FactoryBot.define do
  factory :transaction do
    amount_cents { 10000 }
    state { :pending }
    square_payment_id { "123456" }
  end
end
