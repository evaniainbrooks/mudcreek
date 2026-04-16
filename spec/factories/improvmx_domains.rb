FactoryBot.define do
  factory :improvmx_domain, class: "Improvmx::Domain" do
    status       { :unchecked }
    api_response { {} }
    check_data   { {} }
  end
end
