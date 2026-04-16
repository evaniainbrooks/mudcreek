FactoryBot.define do
  factory :postmark_domain, class: "Postmark::Domain" do
    sequence(:external_id) { |n| n }
    status                 { :unchecked }
    api_response           { {} }
  end
end
