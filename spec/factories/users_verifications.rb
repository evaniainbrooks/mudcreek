FactoryBot.define do
  factory :users_verification, class: "Users::Verification" do
    association :user

    after(:build) do |verification|
      verification.verification_document.attach(
        io: Rails.root.join("spec/fixtures/images/cat.jpg").open("rb"),
        filename: "cat.jpg",
        content_type: "image/jpeg"
      )
    end

    trait :validated do
      status { :validated }
    end
  end
end
