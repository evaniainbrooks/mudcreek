FactoryBot.define do
  factory :invoice do
    association :user
    association :auction
    total_cents { 10_000 }
    status      { :unpaid }

    trait :paid do
      status { :paid }
    end

    trait :with_items do
      after(:create) do |invoice|
        listing = create(:listing, state: :sold)
        create(:invoice_item, invoice: invoice, listing: listing, name: listing.name, amount_cents: 5_025)
        create(:invoice_item, invoice: invoice, listing: create(:listing, state: :sold), name: "Second Item", amount_cents: 5_025)
        invoice.update!(total_cents: 10_050)
      end
    end
  end

  factory :invoice_item do
    association :invoice
    association :listing
    name        { "Winning Bid Item" }
    amount_cents { 5_000 }
  end
end
